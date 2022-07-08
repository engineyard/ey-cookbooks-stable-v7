case node.engineyard.environment["db_stack_name"]
when /postgres/
  include_recipe "ey-postgresql::default"
when /mysql/
  include_recipe "ey-mysql"
  include_recipe "ey-mysql::user_my.cnf"
  include_recipe "ey-mysql::slave"
  include_recipe "ey-mysql::monitoring"
when "no_db"
  # no-op
end

include_recipe "ey-db_admin_tools"
