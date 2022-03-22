file "/etc/engineyard/instance_api.yml" do
  action :create
  owner "root"
  group "root"
  mode "0640"
  content YAML.dump(node.engineyard.instance.instance_api_config.to_hash || {})
end
