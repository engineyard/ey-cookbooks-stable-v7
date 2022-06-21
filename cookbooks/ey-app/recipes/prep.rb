include_recipe "ey-deploy-keys"

unless node.engineyard.instance.solo? # for solo leave the db stuff to the db cookbook
  case node.engineyard.environment["db_stack_name"]
  when /^postgres\d+/, /^aurora-postgresql\d+/
    include_recipe "ey-postgresql::default"
  when /^mysql\d+/, /^aurora\d+/, /^mariadb\d+/
    include_recipe "ey-mysql::client"
    include_recipe "ey-mysql::user_my.cnf"
  when "no_db"
    # no-op
  end
end

include_recipe "ey-app::remove"
include_recipe "ey-app-logs"
include_recipe "ey-app::create"
include_recipe "ey-db-libs"
include_recipe "ey-haproxy"
