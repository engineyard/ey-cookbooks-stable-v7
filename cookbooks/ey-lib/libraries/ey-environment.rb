class Chef
  module EY
    class Environment
      RUBY_REGEXP = /^(ruby)/.freeze

      def initialize(node)
        @node = node
        @hash = @node["dna"]["engineyard"]["environment"]
      end

      def instances
        @hash["instances"]
      end

      def framework_env
        @hash["framework_env"]
      end

      def component?(name)
        @hash["components"].any? { |c| c["key"] == name.to_s }
      end

      def component(name)
        @hash["components"].detect { |c| c["key"] == name.to_s }
      end

      def components
        @hash["components"] || {}
      end

      # Support a more natural way of accessing hash members and components
      def respond_to?(method)
        # @hash.key? method is broken so check keys list
        ([method, method.to_s] - @hash.keys).length < 2 || component?(method.to_s) || super
      end

      def method_missing(method, *args)
        respond_to?(method) ? (@hash[method] || @hash[method.to_s] || component?(method.to_s) || super) : super
      end

      def metadata(key = nil, default = nil)
        unless @component_metadata
          @component_metadata = component("environment_metadata").dup.reject { |k| k == "key" }

          # Apply metadata that is applicable to this environment and remove all other
          @component_metadata.keys.select { |k| k.to_s.match(/^.*\[[^\]]*\]$/) }.each do |key|
            value = @component_metadata.delete(key)
            (base, env_name) = key.match(/^(.*)\[([^\]]*)\]$/)[1..2]
            @component_metadata[base] = value if env_name == self["name"]
          end

        end
        key.nil? ? @component_metadata : @component_metadata.fetch(key.to_s, default)
      end

      def custom_ruby
        return @custom_ruby_version_str if @custom_ruby_version_checked
        v = metadata("ruby_version")
        v = "ruby-#{v}" unless v.nil? || v =~ RUBY_REGEXP
        @custom_ruby_version_checked = true
        @custom_ruby_version_str = v
      end

      def custom_ruby?
        !custom_ruby.nil?
      end

      def custom_rubygems
        metadata("rubygem_version")
      end

      def ruby?
        custom_ruby? ? custom_ruby =~ RUBY_REGEXP : @hash["components"].any? { |c| c["key"] =~ RUBY_REGEXP }
      end

      def rubygems?
        @hash["components"].any? { |c| c["key"] =~ /^rubygems/ }
      end

      def lock_db_version?
        @hash["components"].any? { |c| c["key"] =~ /^lock_db_version/ }
      end

      def app_servers
        instances.select { |i| i["role"] =~ /^app/ }
      end

      def app_private_hostnames
        app_servers.map { |i| i["private_hostname"] }
      end

      def ruby
        return @ruby_component if @ruby_component
        if component = @hash["components"].detect { |c| c["key"] =~ RUBY_REGEXP }
          key = component["key"].to_sym
          r = ruby_package_details(
            custom_ruby || default_ruby_version(key)
          )

          # Rubygems should use the value specified in rubies method if present, otherwise use DNApi value
          r[:rubygems] = custom_rubygems unless custom_rubygems.nil?
          unless r.key? :rubygems
            r[:rubygems] = rubygems? ? components.find_all { |e| e["key"] == "rubygems" }.first["version"] : nil
          end
          @ruby_component = r
        end
      end

      def default_ruby_version(ruby_archtype)
        # According to https://support.cloud.engineyard.com/hc/en-us/articles/360022162773-Engine-Yard-Ubuntu-19-05-Technology-Stack
        versions = {
          ruby_230: "2.3.8",
          ruby_240: "2.4.10",
          ruby_250: "2.5.8",
          ruby_260: "2.6.6",
          ruby_270: "2.7.1",
          ruby_300: "3.0.2",
          ruby_310: "3.1.1",
        }
        if versions.key?(ruby_archtype.to_sym)
          version = versions[ruby_archtype.to_sym]
          "#{ruby_archtype.to_s.sub(/_?[0-9]*$/, '')}-#{version}"
        else
          Chef::Log.fatal "Could not find a default version for ruby '#{ruby_archtype}'"
          exit(1)
        end
      end

      def db_adapter(app_type)
        if @hash["db_stack_name"] == "mysql" && app_type == "rack"
          "mysql2"
        else
          stack_name = @hash["db_stack_name"].gsub /[^a-z]+/, ""
          case stack_name
          when "aurora", "mariadb", "mysql"
            "mysql"
          when "postgres", "aurorapostgresql"
            "postgresql"
          else
            stack_name
          end
        end
      end

      def [](name)
        @hash[name]
      end
    end
  end
end