#
# Cookbook:: dns_failover
# Recipe:: dynect
#

template '/engineyard/bin/dynect_update.rb' do
  source 'dynect_update.rb.erb'
  owner 'root'
  group 'root'
  mode '0755'
  backup 0
  variables({
    provider: node['dns_failover']['provider'],
    customer: node['dns_failover']['customer'],
    username: node['dns_failover']['username'],
    password: node['dns_failover']['password'],
    zone: node['dns_failover']['zone'],
    records: node['dns_failover']['records'],
  })
end

bash 'dynect-update' do
  code '/engineyard/bin/dynect_update.rb'
end
