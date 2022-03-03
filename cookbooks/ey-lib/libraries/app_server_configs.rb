require_relative "env_vars"
require_relative "metadata"

module AppServerConfigs
  module Helper
    def self.included(klass)
      klass.class_eval do
        # Module dependencies
        include EnvVars::Helper
        include EnvMetadata::Helper
      end
    end

    def app_server_get_worker_memory_size(app)
      # See https://support.cloud.engineyard.com/entries/23852283-Worker-Allocation-on-Engine-Yard-Cloud for more details
      mem_size = fetch_env_var_for_app(app, "EY_WORKER_MEMORY_SIZE") || metadata_app_get_with_default(app.name, :worker_memory_size) || "255.0"
    end

    def app_server_get_passenger_grace_time(app)
      grace_time = fetch_env_var_for_app(app, "EY_PASSENGER_GRACE_TIME") || metadata_app_get_with_default(app.name, :passenger_grace_time) || "60"
    end

    def app_server_get_worker_termination_conditions(app)
      # 1. Default conditions
      conditions = fetch_env_var_for_app(app, "EY_WORKER_TERMINATION_CONDITIONS") || metadata_app_get_with_default(app.name, :worker_termination_conditions) || '{"quit": [], "term": [{"cycles": 8}]}'
      conditions = JSON.parse conditions
      base_cycles = (conditions.fetch("quit", []).detect { |h| h.key?("cycles") } || {}).fetch("cycles", 2).to_i
      worker_memory_size = app_server_get_worker_memory_size(app)
      worker_mem_cycle_checks = []
      ["quit", "abrt", "term", "kill"].each do |sig|
        conditions.fetch(sig, []).each do |condition|
          overrun_cycles = condition.fetch("cycles", base_cycles).to_i
          mem = condition.fetch("memory", worker_memory_size).to_f
          worker_mem_cycle_checks << [mem, overrun_cycles, sig]
        end
      end
      {
        base_cycles: base_cycles,
        memory_cycle_checks: worker_mem_cycle_checks,
        memory_size: worker_memory_size,
      }
    end
  end
end

class Chef
  class Recipe
    include AppServerConfigs::Helper
  end

  class Resource
    include AppServerConfigs::Helper
  end
end