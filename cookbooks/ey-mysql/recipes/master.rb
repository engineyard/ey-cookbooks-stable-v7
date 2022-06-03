ey_cloud_report "mysql" do
  message "processing mysql"
end

include_recipe "ey-db-ssl::setup"
include_recipe "ey-mysql::install"
include_recipe "ey-mysql::user_my.cnf"

directory "/db/mysql" do
  owner "mysql"
  group "mysql"
  mode "755"
  recursive true
end

directory node["mysql"]["logbase"] do
  owner "mysql"
  group "mysql"
  mode "755"
  recursive true
end

include_recipe "ey-mysql::startup"

execute "set-root-mysqls-passs" do
  command %(mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '#{node.engineyard.environment['db_admin_password']}'"; true)
end

include_recipe "ey-mysql::setup_app_users_dbs"

include_recipe "ey-backup::mysql"
