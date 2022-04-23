postgres_version = node.engineyard.environment["db_stack_name"] =~ /postgres/ ? node["postgresql"]["short_version"] : "12"
package "postgresql-server-dev-#{postgres_version}"
package "libmysqlclient-dev"
package "libsqlite3-dev"
