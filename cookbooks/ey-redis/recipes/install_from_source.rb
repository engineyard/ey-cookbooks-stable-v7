redis_version = node["redis"]["version"]
redis_download_url = node["redis"]["download_url"]
redis_installer_directory = "/opt/redis-#{redis_version}"

remote_file "/opt/redis-#{redis_version}.tar.gz" do
  source "#{redis_download_url}"
  owner node["owner_name"]
  group node["owner_name"]
  mode "0644"
  backup 0
end

execute "unarchive Redis installer" do
  cwd "/opt"
  command "tar zxf redis-#{redis_version}.tar.gz && sync"
end

execute "run redis-source/make install" do
  cwd redis_installer_directory
  command "make install"
end
