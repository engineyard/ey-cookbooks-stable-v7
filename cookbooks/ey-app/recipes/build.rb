include_recipe "ey-db_admin_tools"

if db_host_is_rds? && node.engineyard.environment[:db_stack_name][/^(mysql\d+|aurora\d+)/]
  include_recipe "ey-mysql::setup_app_users_dbs"
end
