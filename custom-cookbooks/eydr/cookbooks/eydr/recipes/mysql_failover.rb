#
# Cookbook:: dr_failover
# Recipe:: mysql_failover
#

bash 'remove-replication-configuration' do
  code 'rm /db/mysql/master.info'
  only_if { ::File.exist?('/db/mysql/master.info') }
end

bash 'remove-replication-configuration' do
  code 'rm /etc/mysql.d/replication.cnf'
  only_if { ::File.exist?('/etc/mysql.d/replication.cnf') }
end

bash 'remote-replication-relay-files' do
  code 'rm /db/mysql/*relay*'
  only_if { ::File.exist?('/db/mysql/relay-log.info') }
end

case node['engineyard']['environment']['db_stack_name']
when 'mysql5_0', 'mysql5_1'
  ruby_block 'promote-5.0-5.1-slave-to-master' do
    block do
      `mysql -u root -p#{node['owner_pass']} -e 'stop slave;'`
      `mysql -u root -p#{node['owner_pass']} -e 'CHANGE master TO master_host='';'`
      `mysql -u root -p#{node['owner_pass']} -e 'SET global read_only = 0;'`
      `mysql -u root -p#{node['owner_pass']} -e 'flush privileges;'`
    end
  end
when 'mysql5_5'
  ruby_block 'promote-5.5-slave-to-master' do
    block do
      `mysql -u root -p#{node['owner_pass']} -e 'stop slave;'`
      `mysql -u root -p#{node['owner_pass']} -e 'reset slave all;'`
      `mysql -u root -p#{node['owner_pass']} -e 'SET global read_only = 0;'`
      `mysql -u root -p#{node['owner_pass']} -e 'flush privileges;'`
    end
  end
end

bash 'restart-mysql' do
  code '/etc/init.d/mysql restart'
end
