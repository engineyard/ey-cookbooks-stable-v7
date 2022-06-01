postgres_version = node["postgresql"]["short_version"].nil? || node["postgresql"]["short_version"] == {} || node["postgresql"]["short_version"].to_i == 11 ? "all" : node["postgresql"]["short_version"]

apt_repository "posgresql" do
  uri "http://apt.postgresql.org/pub/repos/apt"
  distribution "#{`lsb_release -cs`.strip}-pgdg"
  components ["main"]
  key "https://www.postgresql.org/media/keys/ACCC4CF8.asc"
end

package "postgresql-server-dev-#{postgres_version}"
package "libmysqlclient-dev"
package "libsqlite3-dev"
