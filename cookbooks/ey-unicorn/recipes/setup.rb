ey_cloud_report "ey-unicorn" do
  message "processing unicorn started"
end

directory "/var/log/engineyard/unicorn" do
  owner node.engineyard.environment.ssh_username
  group node.engineyard.environment.ssh_username
  mode "755"
end

directory "/var/run/engineyard" do
  owner node.engineyard.environment.ssh_username
  group node.engineyard.environment.ssh_username
  action :create
  mode "755"
end

node.engineyard.apps.each do |app|
  directory "/var/run/unicorn/#{app.name}" do
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode "755"
    recursive true
  end
end

ey_cloud_report 'ey-unicorn' do
    message 'processing unicorn finished'
end
