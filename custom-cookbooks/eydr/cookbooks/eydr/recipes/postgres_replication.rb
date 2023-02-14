#
# Cookbook:: dr_replication
# Recipe:: postgresql_replication
#

postgres_version = node["postgresql"]["short_version"]

Chef::Log.info("PostgreSQL Version: #{postgres_version}")

if postgres_version_gte?("12")
  execute "touch standby.signal" do
    command "touch /db/postgresql/#{node['postgresql']['short_version']}/data/standby.signal"
  end

  bash "add primary_conninfo in postgresql.conf" do
    user "postgres"
    code <<-EOS
      cat >>/db/postgresql/#{node['postgresql']['short_version']}/data/postgresql.conf <<EOL
primary_conninfo = 'host=127.0.0.1 port=5433 user=postgres password=#{node['owner_pass']}'
    EOS
    not_if "grep -q primary_conninfo /db/postgresql/#{node['postgresql']['short_version']}/data/postgresql.conf"
  end

  bash "add promote_trigger_file in postgresql.conf" do
    user "postgres"
    code <<-EOS
      cat >>/db/postgresql/#{node['postgresql']['short_version']}/data/postgresql.conf <<EOL
promote_trigger_file = '/tmp/postgresql.trigger'
    EOS
    not_if "grep -q promote_trigger_file /db/postgresql/#{node['postgresql']['short_version']}/data/postgresql.conf"
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

bash "remove-trigger-file" do
    code "rm /tmp/postgresql.trigger"
      only_if { ::File.exist?("/tmp/postgresql.trigger") }
end

# Ensure the wal directory exists
directory "/db/postgresql/#{node['postgresql']['short_version']}/wal/" do
  owner "postgres"
  group "postgres"
  mode "0755"
  recursive true
  action :create
end

if postgres_version_gte?("15")
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
    action :create_if_missing
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
    action :create_if_missing
  end
end

# Only run the setup replication script if the enable_replication flag is set to true in the attributes
if node["establish_replication"]
  execute "setup-replication" do
    command "/engineyard/bin/setup_replication.sh"
    timeout 7200  # default 2 hours, if you have a lot of data you may need to increase this
    action :nothing
  end

  if !pg_eydr_replicating_from_master && !pg_eydr_streaming
    execute "check-replication" do
      command "echo 'Replication is set to true.\nExecute setup-replication bash if no replication is ongoing'"
      notifies :run, "execute[setup-replication]", :immediately
    end
  end
end

