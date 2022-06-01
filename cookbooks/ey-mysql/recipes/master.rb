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

set_root_mysql_password = case node["mysql"]["short_version"]
                          when "5.6"
                            %(
      /usr/bin/mysqladmin -u root password '#{node.engineyard.environment['db_admin_password']}' || /usr/bin/mysqladmin -u root --password='' password '#{node.engineyard.environment['db_admin_password']}'; true
    )
                          when "5.7", "8.0"
                            %(
      mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '#{node.engineyard.environment['db_admin_password']}'"; true
    )
                          end

execute "set-root-mysqls-passs" do
  command set_root_mysql_password
end

include_recipe "ey-mysql::cleanup" if node["mysql"]["short_version"] == "5.6" # MySQL 5.7 and 8.0 don't include extra users/databases by default

include_recipe "ey-mysql::setup_app_users_dbs"

include_recipe "ey-backup::mysql"
