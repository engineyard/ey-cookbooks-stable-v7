#
# Cookbook:: dr_replication
# Recipe:: default
#

if ['db_master', 'db_slave', 'solo'].include?(node['dna']['instance_role']) && node['ec2']['public_hostname'] == node['dr_replication'][node['dna']['environment']['framework_env']]['master']['public_hostname']
  Chef::Log.info 'Configuring master for replication'
  include_recipe 'eydr::keys'
  include_recipe "eydr::#{node['dna']['engineyard']['environment']['db_stack_name'].split(/[0-9]/).first}_master_configuration"
end

if ['db_master', 'db_slave', 'solo'].include?(node['dna']['instance_role']) && node['ec2']['public_hostname'] == node['dr_replication'][node['dna']['environment']['framework_env']]['initiate']['public_hostname']
  Chef::Log.info 'Configuring keys and installing Xtrabackup for replication'
  include_recipe 'eydr::keys'
  include_recipe "eydr::#{node['dna']['engineyard']['environment']['db_stack_name'].split(/[0-9]/).first}_master_configuration"
end

if ['db_master', 'db_slave', 'solo'].include?(node['dna']['instance_role']) && node['ec2']['public_hostname'] == node['dr_replication'][node['dna']['environment']['framework_env']]['slave']['public_hostname']
  Chef::Log.info 'Configuring slave for replication'
  include_recipe 'eydr::keys'
  include_recipe 'eydr::ssh_tunnel'
  include_recipe "eydr::#{node['dna']['engineyard']['environment']['db_stack_name'].split(/[0-9]/).first}_replication"

  if node['failover']
    Chef::Log.info 'Failing over initiated...'
    include_recipe "eydr::#{node['dna']['engineyard']['environment']['db_stack_name'].split(/[0-9]/).first}_monitoring"
    Chef::Log.info 'Current database master has been promoted to slave'
  end
end

# Failover section
if node['failover'] && node['ec2']['public_hostname'] == node['dr_replication'][node['dna']['environment']['framework_env']]['slave']['public_hostname']
  if ['solo', 'db_master'].include?(node['dna']['instance_role'])
    include_recipe "eydr::#{node['dna']['engineyard']['environment']['db_stack_name'].split(/[0-9]/).first}_failover"
  end

  if node['dns_failover']['enabled'] && ['app_master'].include?(node['dna']['instance_role'])
    include_recipe 'eydr::dns_failover'
  end
end
