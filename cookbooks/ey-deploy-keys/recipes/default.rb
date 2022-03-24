ey_cloud_report "deploy keys" do
  message "processing deploy keys"
end

directory "user .ssh directory" do
  path "/home/#{node['owner_name']}/.ssh"
  owner node["owner_name"]
  group node["owner_name"]
  mode "0700"
  action :create
end

node["dna"]["applications"].each do |app, data|
  if data[:deploy_key]

    file "/root/.ssh/#{app}-deploy-key" do
      action :create
      owner "root"
      group "root"
      mode "0600"
      content data[:deploy_key]
    end

    file "/home/#{node['owner_name']}/.ssh/#{app}-deploy-key" do
      action :create
      owner node["owner_name"]
      group node["owner_name"]
      mode "0600"
      content data[:deploy_key]
    end
  end
end
