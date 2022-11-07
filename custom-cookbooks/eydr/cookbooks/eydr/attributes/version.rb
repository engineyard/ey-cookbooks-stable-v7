case node.engineyard.environment['db_stack_name']
when 'mysql5_7'
  default['mysql']['latest_version'] = '5.7.37'
  default['mysql']['virtual'] = '5.7'
  default['mysql']['short_version'] = '5.7'
  default['mysql']['datadir'] = "/db/mysql/#{node['mysql']['short_version']}/data/"
when 'mysql8_0'
  default['mysql']['latest_version'] = '8.0.28'
  default['mysql']['virtual'] = '8.0'
  default['mysql']['short_version'] = '8.0'
  default['mysql']['datadir'] = "/db/mysql/#{node['mysql']['short_version']}/data/"
when 'postgres9_5'
  default['postgresql']['latest_version'] = '9.5.25'
  default["postgresql"]["short_version"] = "9.5"
  default['postgresql']['datadir'] = "/db/postgresql/#{node['postgresql']['short_version']}/data/"
when 'postgres9_6'
  default['postgresql']['latest_version'] = '9.6.24'
  default['postgresql']['short_version'] = '9.6'
  default['postgresql']['datadir'] = "/db/postgresql/#{node['postgresql']['short_version']}/data/"
when 'postgres10'
  default['postgresql']['latest_version'] = '10.20'
  default['postgresql']['short_version'] = '10'
  default['postgresql']['datadir'] = "/db/postgresql/#{node['postgresql']['short_version']}/data/"
when 'postgres11'
  default['postgresql']['latest_version'] = '11.16'
  default['postgresql']['short_version'] = '11'
  default['postgresql']['datadir'] = "/db/postgresql/#{node['postgresql']['short_version']}/data/"
end
