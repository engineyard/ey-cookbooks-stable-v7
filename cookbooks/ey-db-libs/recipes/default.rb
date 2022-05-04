postgres_version = node["postgresql"]["short_version"].nil? || node["postgresql"]["short_version"].to_i == 11 ? "all" : node["postgresql"]["short_version"]

Chef::Log.info "Postgres package is #{postgres_version}"

package "postgresql-server-dev-#{postgres_version}"
package "libmysqlclient-dev"
package "libsqlite3-dev"
