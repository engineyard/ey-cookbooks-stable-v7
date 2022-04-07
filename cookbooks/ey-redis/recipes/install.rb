redis_version = (node["redis"]["version"] || "4.0.9")
# Deduce the redis_config_file_version from the full Redis version string
#   1. remove possible -RCx in version
#   2. split into major, minor, and (optionally) patch version components
#   3. use major.minor as redis_config_file_version
version_regex = /(\d+)\.(\d+)(\.\d+)?(-rc\d+)?/i
if vmatch = version_regex.match(redis_version)
  redis_config_file_version = "#{vmatch[1]}.#{vmatch[2]}"
else
  Chef::Log.fatal "Invalid Redis version."
  exit(1)
end
redis_base_directory = node["redis"]["basedir"]

run_installer = !::FileTest.exists?(redis_base_directory) || node["redis"]["force_upgrade"]

redis_bin_path = node["redis"]["install_from_source"] ? "/usr/local/bin/redis-server" : "/usr/bin/redis-server"

# check if redis-server exists
unless ::File.exist?(redis_bin_path)
  run_installer = true
end

if node["redis"]["is_redis_instance"]

  sysctl "vm.overcommit_memory" do
    value 1
  end

  thp_filename = "/sys/kernel/mm/transparent_hugepage/enabled"
  transparent_hugepage_command = "echo never > #{thp_filename}"
  if ::File.exist?(thp_filename)
    execute "disable transparent huge pages when present" do
      command transparent_hugepage_command
    end

    execute "set #{thp_filename} on boot" do
      command "sed -i '1a #{transparent_hugepage_command}' /etc/rc.local"
      only_if { ::File.exist?("/etc/rc.local") }
      not_if "grep -e '#{transparent_hugepage_command}' /etc/rc.local"
    end
  end

  group "redis" do
    not_if "getent group redis"
  end

  user "redis" do
    username "redis"
    group "redis"
    home "/var/lib/redis"
    system true
    not_if "getent passwd redis"
  end

  [redis_base_directory, "/var/run/redis", "/var/lib/redis", "/etc/redis"].each do |dir|
    directory dir do
      owner "redis"
      group "redis"
      mode "0755"
      recursive true
      action :create
    end
  end

  redis_config_variables = {
    basedir: node["redis"]["basedir"],
    basename: node["redis"]["basename"],
    logfile: node["redis"]["logfile"],
    loglevel: node["redis"]["loglevel"],
    port: node["redis"]["port"],
    saveperiod: node["redis"]["saveperiod"],
    timeout: node["redis"]["timeout"],
    databases: node["redis"]["databases"],
    rdbcompression: node["redis"]["rdbcompression"],
    rdb_filename: node["redis"]["rdb_filename"],
    hz: node["redis"]["hz"],
  }

  if node["dna"]["instance_role"] != "solo" && !node["redis"]["slave_name"].to_s.empty? && node["dna"]["name"] == node["redis"]["slave_name"]
    redis_config_template = "redis-#{redis_config_file_version}-slave.conf.erb"

    # TODO: Move this to a function
    instances = node["dna"]["engineyard"]["environment"]["instances"]
    redis_master_instance = instances.find { |i| i["name"] == node["redis"]["utility_name"] }

    if redis_master_instance.nil?
      raise "Redis utility instance named '#{node['redis']['utility_name']}' doesn't exist"
    end

    redis_config_variables["master_ip"] = redis_master_instance["private_hostname"]
  else
    redis_config_template = "redis-#{redis_config_file_version}.conf.erb"
  end

  redis_config_path = "/etc/redis/redis.conf"
  template redis_config_path do
    owner "redis"
    group "redis"
    mode "0644"
    source redis_config_template
    variables redis_config_variables
  end

  service "redis-server" do
    provider Chef::Provider::Service::Systemd
    action :nothing
  end

  template "/etc/systemd/system/redis-server.service" do
    owner "root"
    group "root"
    mode "0644"
    source "redis-server.service.erb"
    variables(
      redis_bin_path: redis_bin_path,
      redis_config_path: redis_config_path,
      basedir: node["redis"]["basedir"]
    )
    notifies :run, "execute[reload-systemd]", :immediately
    notifies :enable, "service[redis-server]", :immediately
    notifies :restart, "service[redis-server]" # restart after installing redis
  end

  if run_installer
    if node["redis"]["install_from_source"]
      include_recipe "ey-redis::install_from_source"
    else
      include_recipe "ey-redis::install_from_package"
    end
  end

  service "start redis-server" do
    service_name "redis-server"
    provider Chef::Provider::Service::Systemd
    action :start
  end
end
