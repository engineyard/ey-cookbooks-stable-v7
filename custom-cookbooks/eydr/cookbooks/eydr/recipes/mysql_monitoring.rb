#
# Cookbook:: dr_failover
# Recipe:: mysql_monitoring
#

bash "add-mysql-replication-monitoring" do
  code 'sed -i \'s|Exec "mysql" "/engineyard/bin/check_mysql.sh" "connections"|Exec "mysql" "/engineyard/bin/check_mysql.sh" "connections"\n      Exec "mysql" "/engineyard/bin/check_mysql.sh" "replication" "8000" "40000"|g\' /etc/engineyard/collectd.conf'
  not_if "grep 'replication' /etc/engineyard/collectd.conf"
  only_if { ::File.exist?("/etc/engineyard/collectd.conf") }
end
