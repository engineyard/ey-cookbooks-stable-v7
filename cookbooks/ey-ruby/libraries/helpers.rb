module RubyHelpers
  def is_ruby_jemalloc_enabled(node)
    fetch_env_var(node, "EY_RUBY_JEMALLOC") =~ /^TRUE$/i
  end
end

Chef::Node.send(:include, RubyHelpers)
Chef::DSL::Recipe.send(:include, RubyHelpers)
Chef::Resource.send(:include, RubyHelpers)
