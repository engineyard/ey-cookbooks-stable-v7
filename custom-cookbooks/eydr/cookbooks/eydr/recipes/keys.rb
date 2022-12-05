#
# Cookbook:: dr_replication
# Recipe:: keys
#

private_key = metadata_any_get_with_default("eydr_private_key", "<ADD TO METADATA>")
public_key = metadata_any_get_with_default("eydr_public_key", "<ADD TO METADATA>")

file "/home/#{node['owner_name']}/.ssh/eydr_key" do
  owner node["owner_name"]
  group node["owner_name"]
  mode "0600"
  action :create
  content private_key
end

file "/home/#{node['owner_name']}/.ssh/eydr_key.pub" do
  owner node["owner_name"]
  group node["owner_name"]
  mode "0600"
  action :create
  content public_key
end

if node["dna"]["engineyard"]["environment"]["db_stack_name"] =~ /postgres/
  directory "/var/lib/postgresql/.ssh/" do
    owner "postgres"
    group "postgres"
    mode "0755"
    recursive true
    action :create
  end

  bash "touch-postgresql-authorized-keys" do
    user "postgres"
    code "touch /var/lib/postgresql/.ssh/authorized_keys"
    not_if { ::File.exist?("/var/lib/postgresql/.ssh/authorized_keys") }
  end

  file "/var/lib/postgresql/.ssh/id_rsa" do
    owner "postgres"
    group "postgres"
    mode "0700"
    backup 0
    content private_key
  end

  file "/var/lib/postgresql/.ssh/id_rsa.pub" do
    owner "postgres"
    group "postgres"
    mode "0700"
    backup 0
    content public_key
  end

  bash "configure-authorized-keys-for-postgres" do
    code "cat /var/lib/postgresql/.ssh/id_rsa.pub >> /var/lib/postgresql/.ssh/authorized_keys"
    not_if 'grep "`cat /var/lib/postgresql/.ssh/id_rsa.pub`" /var/lib/postgresql/.ssh/authorized_keys'
  end
end
