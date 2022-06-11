directory "/opt/nodejs" do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
  action :create
end

node_version = node['nodejs']['version']
node_download_url = "https://nodejs.org/download/release/v#{node_version}/node-v#{node_version}-linux-x64.tar.gz"
node_tarball_filename = "node-v#{node_version}-linux-x64.tar.gz"
node_package_directory = "node-v#{node_version}-linux-x64"

if node.engineyard.instance.arch_type == "arm64"
  node_download_url = "https://nodejs.org/download/release/v#{node_version}/node-v#{node_version}-linux-arm64.tar.gz"
  node_tarball_filename = "node-v#{node_version}-linux-arm64.tar.gz"
  node_package_directory = "node-v#{node_version}-linux-arm64"
end

execute "downloading nodejs" do
  cwd "/opt/nodejs"
  command "wget #{node_download_url}"
  not_if { File.exist?("/opt/nodejs/#{node_tarball_filename}") }
end

execute "unarchive nodejs installer" do
  cwd "/opt/nodejs"
  command "tar zxf #{node_tarball_filename}"
  not_if { Dir.exist?("/opt/nodejs/#{node_package_directory}") }
end

link "/usr/bin/node" do
  to "/opt/nodejs/#{node_package_directory}/bin/node"
end

link "/usr/bin/npm" do
  to "/opt/nodejs/#{node_package_directory}/bin/npm"
end

link "/opt/nodejs/current" do
  to "/opt/nodejs/#{node_package_directory}-linux-x64"
end
