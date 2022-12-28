ey_cloud_report "Datadog" do
  message "processing datadog config"
end

apt_package "apt-transport-https"
apt_package "acl"

cookbook_file "/tmp/installer.sh" do
  source "installer.sh"
  mode "0755"
end

execute "installer" do
  command "sh /tmp/installer.sh"
  # action :nothing
  notifies :install, "apt_package[datadog-signing-keys]", :immediately
  notifies :install, "apt_package[datadog-agent]", :immediately
  not_if { ::File.exist?("/etc/datadog_installed.txt") }
end

apt_package "datadog-signing-keys" do
  action :nothing
  # notifies :install, "apt_package[datadog-agent]", :immediate
end

apt_package "datadog-agent" do
  action :nothing
  notifies :create, "template[datadog.yaml]", :immediately
end

has_db = ["solo", "db_master", "db_slave"].include?(node["dna"]["instance_role"])

execute "give datadog access to log files" do
  command "/usr/bin/setfacl -m g:dd-agent:rx /var/log/syslog"
  command "/usr/bin/setfacl -m g:dd-agent:rx /var/log/auth.log"
  command "/usr/bin/setfacl -m g:dd-agent:rx /var/log/daemon.log"
  if has_db
    command "/usr/bin/setfacl -m g:dd-agent:rx /db/mysql/5.7/log/mysqld.err"
    command "/usr/bin/setfacl -m g:dd-agent:rx /db/mysql/5.7/log/slow_query.log"
  end
end

template "datadog.yaml" do
  path "/etc/datadog-agent/datadog.yaml"
  source "datadog.yaml.erb"
  owner "dd-agent"
  group "dd-agent"
  mode "0640"
  backup 12
  variables({
    api_key: node["datadog"]["api_key"],
    service: node["datadog"]["service"],
    env: node.engineyard.environment["framework_env"],
    environment: node.engineyard.environment["name"],
    instance_role: node["dna"]["instance_role"],
    instance_name: node["dna"]["name"],
    site: node["datadog"]["site"],
    logs_enabled: node["datadog"]["logs_enabled"],
    process_config: node["datadog"]["process_config"],
  })
end

directory "/etc/datadog-agent/conf.d/logs.d/" do
  owner "dd-agent"
  group "dd-agent"
end

template "Logs" do
  path "/etc/datadog-agent/conf.d/logs.d/config.yaml"
  source "logconfig.yaml.erb"
  owner "dd-agent"
  group "dd-agent"
  mode "0640"
  backup 12
  variables({
    service: node["datadog"]["service"],
    env: node.engineyard.environment["framework_env"],
    applications: node["dna"]["applications"],
    instance_role: node["dna"]["instance_role"],
    instance_name: node["dna"]["name"],
    include_dj: node["dna"]["name"] == "delayed_job",
    include_database: has_db,
    mysql_short_version: node["mysql"]["short_version"],
  })
  # action :nothing
  notifies :enable, "service[datadog-agent]", :immediately
  notifies :restart, "service[datadog-agent]", :immediately
end

template "syslog-ng.conf" do
  path "/etc/syslog-ng/syslog-ng.conf"
  source "syslog-ng.conf.erb"
  owner "root"
  group "root"
  mode "0755"
  backup 0

  # instance = node.dna.engineyard.environment.instances.detect { |i| i['id'] == node.dna.engineyard['this'] }
  this = node["dna"]["engineyard"]["this"]
  instance = node["dna"]["engineyard"]["environment"]["instances"].find { |instance| instance["id"] == this }

  variables({
    api_key: node["datadog"]["api_key"],
    datadog_site: node["datadog"]["site"],
    env: node.engineyard.environment["framework_env"],
    instance_id: instance["id"],
  })

  notifies :restart, "service[syslog-ng]", :immediately
end

# Add log rotation for the elasticsearch logs
template "dd-agent_ACLS" do
  path "/etc/logrotate.d/dd-agent_ACLS"
  source "dd-agent_ACLS.logrotate.erb"
  owner "root"
  group "root"
  mode "0644"
  backup 0
  variables({
    include_database: has_db,
  })
end

service "datadog-agent" do
  action [:enable, :start]
end
