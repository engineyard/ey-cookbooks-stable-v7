postgres_version = node["postgresql"]["short_version"].nil? || node["postgresql"]["short_version"] == {} || node["postgresql"]["short_version"].to_i == 11 ? "all" : node["postgresql"]["short_version"]

# Only add PostgreSQL repository and install PostgreSQL dev packages when actually using PostgreSQL stack
if node["dna"]["engineyard"]["environment"]["db_stack_name"] =~ /^postgres|^aurora-postgresql/
  apt_repository "posgresql" do
    uri "https://apt-archive.postgresql.org/pub/repos/apt"
    distribution "#{`lsb_release -cs`.strip}-pgdg-archive"
    components ["main"]
    key "https://www.postgresql.org/media/keys/ACCC4CF8.asc"
  end

  package "postgresql-server-dev-#{postgres_version}"
end
package "libmysqlclient-dev"
package "libsqlite3-dev"
