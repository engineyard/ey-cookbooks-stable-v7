if node.engineyard.environment.ruby?
  env_var_ruby = fetch_env_var(node, "EY_RUBY_VERSION")
  default[:ruby][:version] = !env_var_ruby.nil? ? env_var_ruby : node.engineyard.environment.ruby[:version]
  default[:ruby][:name] = is_ruby_jemalloc_enabled(node) ? "rubyjemalloc" : "ruby"
end
