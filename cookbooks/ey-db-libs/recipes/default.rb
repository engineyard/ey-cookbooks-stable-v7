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
else
  # Clean up legacy PGDG repository file on non-PostgreSQL stacks
  # This addresses GHI-14034: existing instances that already have the file from earlier runs
  file "/etc/apt/sources.list.d/posgresql.list" do
    action :delete
    only_if { ::File.exist?("/etc/apt/sources.list.d/posgresql.list") }
  end
  
  ey_cloud_report "postgresql cleanup" do
    message "Cleaned up legacy PGDG repository file on non-PostgreSQL stack"
    only_if { ::File.exist?("/etc/apt/sources.list.d/posgresql.list") }
  end
end
package "libmysqlclient-dev"
package "libsqlite3-dev"
