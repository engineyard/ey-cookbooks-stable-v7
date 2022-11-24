#
# Cookbook:: dr_replication
# Recipe:: postgresql_replication
#

if node["postgresql"]["short_version"] >= "12"
  execute "touch standby.signal" do
    command "touch /db/postgresql/#{node['postgresql']['short_version']}/data/standby.signal"
  end

  ruby_block "add replication settings" do
    block do
      config_line = "primary_conninfo = 'host=127.0.0.1 port=5433 user=postgres password=#{node['owner_pass']}\npromote_trigger_file = '/tmp/postgresql.trigger'"
      file = Chef::Util::FileEdit.new("/db/postgresql/#{node['postgresql']['short_version']}/custom.conf")
      file.insert_line_if_no_match(/#{Regexp.escape(config_line)}/, config_line)
      file.write_file
    end
  end
else
  # Drop slave replication settings in place
  template "/db/postgresql/#{node['postgresql']['short_version']}/data/recovery.conf" do
    source "recovery.conf.erb"
    owner "postgres"
    group "postgres"
    mode "0600"
    backup 0
    variables(
      standby_mode: "on",
      primary_host: "127.0.0.1",
      primary_port: 5433,
      primary_user: "postgres",
      primary_password: node["owner_pass"],
      trigger_file: "/tmp/postgresql.trigger"
    )
  end
end

# Ensure the wal directory exists
directory "/db/postgresql/#{node['postgresql']['short_version']}/wal/" do
  owner "postgres"
  group "postgres"
  mode "0755"
  recursive true
  action :create
end

if node["postgresql"]["short_version"] >= "15"
  # Render the script to setup replication
  template "/engineyard/bin/setup_replication.sh" do
    source "setup_postgres_15_replication.sh.erb"
    owner "root"
    group "root"
    mode "0755"
    backup 0
    variables(
      master_public_hostname: node["dr_replication"][node["dna"]["environment"]["framework_env"]]["master"]["public_hostname"],
      slave_public_hostname: node["dr_replication"][node["dna"]["environment"]["framework_env"]]["slave"]["public_hostname"],
      version: node["postgresql"]["short_version"]
    )
  end
else
  # Render the script to setup replication
  template "/engineyard/bin/setup_replication.sh" do
    source "setup_postgres_replication.sh.erb"
    owner "root"
    group "root"
    mode "0755"
    backup 0
    variables(
      master_public_hostname: node["dr_replication"][node["dna"]["environment"]["framework_env"]]["master"]["public_hostname"],
      slave_public_hostname: node["dr_replication"][node["dna"]["environment"]["framework_env"]]["slave"]["public_hostname"],
      version: node["postgresql"]["short_version"]
    )
  end
end

# Only run the setup replication script if the enable_replication flag is set to true in the attributes
if node["establish_replication"]
  bash "setup-replication" do
    code "/engineyard/bin/setup_replication.sh"
    timeout 7200  # default 2 hours, if you have a lot of data you may need to increase this
  end
end
