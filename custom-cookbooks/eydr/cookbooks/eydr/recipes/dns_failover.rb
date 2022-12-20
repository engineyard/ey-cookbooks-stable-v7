#
# Cookbook:: dns_failover
# Recipe:: default
#

include_recipe "eydr::#{node['dns_failover']['provider']}"
