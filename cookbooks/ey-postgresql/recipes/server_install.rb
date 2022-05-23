postgres_version = node["postgresql"]["short_version"]
install_version = node["postgresql"]["latest_version"]
known_versions = []
`apt-cache madison postgresql-server-dev-#{postgres_version} |awk '{print $3'}`.split(/\n+/).each { |v| known_versions.append(v.split("-")[0]) }
package_version = known_versions.detect { |v| v =~ /^#{install_version}/ }

execute "dropping lock version file" do
  command "echo #{running_pg_version} > #{node['lock_version_file']}"
  action :run
  only_if { lock_db_version && !File.exist?(node["lock_version_file"]) && pg_running }
end

execute "remove lock version file" do
  command "rm #{node['lock_version_file']}"
  only_if { !lock_db_version && File.exist?(node["lock_version_file"]) }
end

ey_cloud_report "postgresql" do
  message "Handling PostgreSQL Install"
end

directory "/etc/postgresql-common" do
  action :create
end

cookbook_file "/etc/postgresql-common/createcluster.conf" do
  source "createcluster.conf"
end

apt_repository "posgresql" do
  uri "https://apt-archive.postgresql.org/pub/repos/apt"
  distribution "#{`lsb_release -cs`.strip}-pgdg-archive"
  components ["main"]
end

directory "/tmp/src/postgresql" do
  action :create
  recursive true
end

# This ruby block handles if the lock version file is set
# It needs to be done like this since the file isn't present during the compile
# phase on first runs on new instances booted from snapshots
# If a lock version file exists, use the version to set the variables
# on template "/tmp/src/postgresql/install.sh"
ruby_block "check lock version" do
  block do
    install_version = if File.exist?(node["lock_version_file"])
                        `cat #{node["lock_version_file"]}`.strip
                      else
                        node["postgresql"]["latest_version"]
                      end
    package_version = known_versions.detect { |v| v =~ /^#{install_version}/ }
    if package_version.nil?
      raise "Chef does not know about PostgreSQL version #{install_version} the current known versions of PostgreSQL for version #{postgres_version} are the following: #{known_versions} or contact support for more assistance"
    end
    run_context.resource_collection.find(template: "/tmp/src/postgresql/install.sh").variables package_version: package_version, postgres_version: postgres_version
  end
end

template "/tmp/src/postgresql/install.sh" do
  source "install.sh.erb"
  owner "root"
  group "root"
  mode "0755"
  variables package_version: package_version, postgres_version: postgres_version
end

# Install postgresql packages using a script
execute "run postgresql install.sh" do
  command "/tmp/src/postgresql/install.sh"
end

template "/etc/profile.d/postgresql.sh" do
  source "postgresql.sh.erb"
  variables version: postgres_version
end
