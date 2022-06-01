require "tempfile"
require "open-uri"

provides :postgresql_slave
unified_mode true
property :password, String
property :name, String, default: "deploy"
property :postgres_version, String, default: "11.16"

default_action :postgresql_slave_action

action :postgresql_slave_action do
  ruby_block "clean up half-done install" do
    block do
      system("systemctl stop postgresql")
      system("umount /db")
      FileUtils.rmdir "/db"
    end
    only_if { ::File.exist?("/db") }
  end

  execute "stop postgresql" do
    command "systemctl stop postgresql"
  end

  directory "/db" do
    owner "postgres"
    group "postgres"
    mode "755"
    recursive true
  end

  ruby_block "wait-for-db-slave-volume" do
    block do
      sleep 5 until node["db_volume"].found?
    end
  end

  mount "/db" do
    fstype node["db_filesystem"]
    device node["db_volume"].device
    action [:mount, :enable]
  end

  ruby_block "wait-for-db-slave-mount" do
    block do
      until system("ls -l /db/postgresql")
        sleep 3
        Array(resources(mount: "/db")).each do |resource|
          resource.run_action(:mount)
        end
      end
    end
  end
end