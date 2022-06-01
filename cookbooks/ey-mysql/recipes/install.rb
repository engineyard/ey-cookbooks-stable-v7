lock_db_version = node.engineyard.environment.components.find_all { |e| e["key"] == "lock_db_version" }.first["value"] if node.engineyard.environment.lock_db_version?

lock_version_file = "/db/.lock_db_version"
db_running = `mysql -N -e "select 1;" 2> /dev/null`.strip == "1"

known_versions = {
  # mysql 8.0
  "8.0.28" => "https://downloads.percona.com/downloads/Percona-Server-8.0/Percona-Server-8.0.28-19/binary/debian/focal/x86_64/Percona-Server-8.0.28-19-r31e88966cd3-focal-x86_64-bundle.tar",
  "8.0.27" => "https://downloads.percona.com/downloads/Percona-Server-8.0/Percona-Server-8.0.27-18/binary/debian/focal/x86_64/Percona-Server-8.0.27-18-r24801e21b45-focal-x86_64-bundle.tar",
  # mysql 5.7
  "5.7.37" => "https://downloads.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.37-40/binary/debian/focal/x86_64/Percona-Server-5.7.37-40-r3a1347ec0d4-focal-x86_64-bundle.tar",
  "5.7.36" => "https://downloads.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.36-39/binary/debian/focal/x86_64/Percona-Server-5.7.36-39-r305619d-focal-x86_64-bundle.tar",
  "5.7.35" => "https://downloads.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.35-38/binary/debian/focal/x86_64/Percona-Server-5.7.35-38-r3692a61-focal-x86_64-bundle.tar",
  # mysql 5.6
  "5.6.47" => "https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.47-87.0/binary/debian/bionic/x86_64/Percona-Server-5.6.47-87.0-r9ad342b-bionic-x86_64-bundle.tar",
  "5.6.44" => "https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.44-86.0/binary/debian/bionic/x86_64/Percona-Server-5.6.44-86.0-reba1b3f-bionic-x86_64-bundle.tar",
  "5.6.43" => "https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.43-84.3/binary/debian/bionic/x86_64/Percona-Server-5.6.43-84.3-r71967c9-bionic-x86_64-bundle.tar",
  "5.6.42" => "https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.42-84.2/binary/debian/bionic/x86_64/Percona-Server-5.6.42-84.2-r6b2b987-bionic-x86_64-bundle.tar",
  "5.6.41" => "https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.41-84.1/binary/debian/bionic/x86_64/Percona-Server-5.6.41-84.1-rb308619-bionic-x86_64-bundle.tar",
  "5.6.40" => "https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.40-84.0/binary/debian/bionic/x86_64/Percona-Server-5.6.40-84.0-r47234b3-bionic-x86_64-bundle.tar",
  "5.6.39" => "https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.39-83.1/binary/debian/bionic/x86_64/Percona-Server-5.6.39-83.1-rda5a1c2923f-bionic-x86_64-bundle.tar",
}

# create or delete /db/.lock_db_version
if node["dna"]["instance_role"][/^(db|solo)/]
  execute "dropping lock version file" do
    command "echo $(mysql --version | grep -E -o '(Distrib|Ver) [0-9]+\.[0-9]+\.[0-9]+' | awk '{print $NF}') > #{lock_version_file}"
    action :run
    only_if { lock_db_version and !File.exist?(lock_version_file) and db_running }
  end

  execute "remove lock version file" do
    command "rm #{lock_version_file}"
    only_if { !lock_db_version and File.exist?(lock_version_file) }
  end
end

# install the dependencies of the Percona packages
["debsums", "libaio1", "libmecab2"].each do |package|
  package package
end

if node["mysql"]["short_version"] == "5.6"
  package "libdbi-perl"
  package "libdbd-mysql-perl"
end

package "libmysqlclient-dev"

case node["mysql"]["short_version"]
when "5.6"
  packages = ["percona-server-common", "libperconaserverclient18.1_", "percona-server-client"]
when "5.7"
  packages = ["percona-server-common", "percona-server-client"]
when "8.0"
  packages = ["percona-server-common", "libperconaserverclient21_", "percona-server-client"]
end

if node["dna"]["instance_role"][/db|solo/]
  directory "/etc/systemd/system/mysql.service.d" do
    owner "root"
    group "root"
    mode "755"
    recursive true
  end

  cookbook_file "/etc/systemd/system/mysql.service.d/override.conf" do
    source "mysql_override.conf"
    owner "root"
    group "root"
    mode "644"
    notifies :run, "execute[reload-systemd]", :immediately
  end

  packages << "percona-server-server"
end

ruby_block "install mysql using version on lock file if present" do
  block do
    # check if the version is valid
    install_version = if File.exist?(lock_version_file)
                        `cat #{lock_version_file}`.strip
                      else
                        node["mysql"]["latest_version"]
                      end
    package_url = known_versions[install_version]

    if package_url.nil?
      Chef::Log.info "Chef does not know about MySQL version #{install_version}"
      exit(1)
    else
      Chef::Log.info "lock_db_version: #{lock_db_version}, Installing: #{install_version}"
      Chef::Log.debug "Download URL: #{package_url}"
    end

    # download tar file if it doesn't exist
    download_command = %(
      if [ ! -f /tmp/src/Percona-Server-#{install_version}.tar ]; then
        curl -o /tmp/src/Percona-Server-#{install_version}.tar #{package_url}
      fi
      rm -rf /tmp/src/Percona-Server-#{install_version} && mkdir -p /tmp/src/Percona-Server-#{install_version}
      tar xvf /tmp/src/Percona-Server-#{install_version}.tar -C /tmp/src/Percona-Server-#{install_version}
    )
    ` #{download_command} `

    # install the packages using apt install ...deb
    packages.each do |package|
      install_command = %{
        installed=$(apt-cache policy #{package}-#{node['mysql']['short_version']} | grep "Installed: #{install_version}-" > /dev/null)
        if [ $? -ne 0 ]; then
          echo 'Installing #{package} for #{node['mysql']['short_version']}'
          DEBIAN_FRONTEND=noninteractive apt install --yes --force-yes --allow-downgrades -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" /tmp/src/Percona-Server-#{install_version}/#{package}*.deb
        else
          echo '#{package} for #{node['mysql']['short_version']} is already installed'
        fi
      }
      ` #{install_command} `
    end
  end
end
