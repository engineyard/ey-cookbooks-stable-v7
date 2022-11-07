#
# Cookbook:: dr_replication
# Recipe:: mysql_replication
#

include_recipe 'eydr::install_xtrabackup'

# Drop slave replication settings in place
template '/etc/mysql.d/replication.cnf' do
  source 'replication.cnf.erb'
  variables({
    server_id: node['engineyard']['this'].split('-')[1].to_i(16),
    datadir: node['datadir'],
    short_version: node['mysql']['short_version'],
  })
end

# Render the script to setup replication
template '/engineyard/bin/setup_replication.sh' do
  source 'setup_mysql_replication.sh.erb'
  owner 'root'
  group 'root'
  mode '0755'
  backup 0
  variables({
    master_pass: node['owner_pass'],
    initiate_public_hostname: node['dr_replication'][node['environment']['framework_env']]['initiate']['public_hostname'],
    slave_public_hostname: node['dr_replication'][node['environment']['framework_env']]['slave']['public_hostname'],
    master_public_hostname: node['dr_replication'][node['environment']['framework_env']]['master']['public_hostname'],
    datadir: node['datadir'],
    user: node['owner_name'],
    db_name: node['engineyard']['environment']['apps'].first['database_name'],
    db_pass: node['owner_pass'],
    db_user: node['owner_name'],
  })
end

# Only run the setup replication script if the enable_replication flag is set to true in the attributes
if node['establish_replication']
  bash 'setup-replication' do
    code "/engineyard/bin/setup_replication.sh > /home/#{node['owner_name']}/setup_replication.log 2>&1"
    timeout 7200  # default 2 hours, if you have a lot of data you may need to increase this
  end
end
