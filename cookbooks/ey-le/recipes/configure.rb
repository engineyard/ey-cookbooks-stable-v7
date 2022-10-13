#
# Cookbook Name:: ey-le
# Recipe:: configure
#

execute "le register --account-key" do
  command "/usr/bin/le register --account-key #{node['le']['le_api_key']} --name #{node['dna']['applications'].keys.first}/#{node['dna']['engineyard']['this']}"
  action :run
  not_if { File.exists?('/etc/le/config') }
end

follow_paths = [
  "/var/log/syslog",
  "/var/log/auth.log",
  "/var/log/daemon.log"
]
(node['dna']['applications'] || []).each do |app_name, app_info|
  follow_paths << "/var/log/nginx/#{app_name}.access.log"
end

follow_paths.each do |path|
  execute "le follow #{path}" do
    command "le follow #{path}"
    ignore_failure true
    action :run
    not_if "le followed #{path}"
  end
end
