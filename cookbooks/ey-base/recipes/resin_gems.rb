resin_path = "/usr/local/ey_resin/ruby/bin"
gem_bin_path = "/opt/chef/embedded/bin"
bin_path = "/usr/local/bin"

snaplock_version = "2.0.4"
execute "install ey-snaplock" do
  command "wget https://ey-primer-gems.s3.amazonaws.com/ey_snaplock-#{snaplock_version}.gem && #{gem_bin_path}/gem install /tmp/ey_snaplock-#{snaplock_version}.gem"
  cwd "/tmp"
  not_if "#{gem_bin_path}/gem list ey_snaplock | grep #{snaplock_version}"
end

# 1.5.1 fixes a database restore that could drop the application database
# and then fail to recreate it on MySQL 8.0.16+, leaving the environment with
# no database while still reporting success. It also restores the replica-safety
# check that MySQL 8.4 disabled by removing SHOW SLAVE STATUS, and makes
# failed restores exit non-zero.
chef_gem "ey_cloud_server" do
  version "1.5.1"
  compile_time false
end

chef_gem "ey_services_setup" do
  version "0.0.8"
  compile_time false
end

chef_gem "ey_stonith" do
  version "0.4.3.pre1"
  compile_time false
end

["eybackup", "eyrestore", "ey-snapshots", "ey-snaplock"].each do |executable|
  link "#{bin_path}/#{executable}" do
    to "#{gem_bin_path}/#{executable}"
    only_if { ::File.exist?("#{gem_bin_path}/#{executable}") }
  end
end

# executable needed for deploys
directory resin_path do
  owner "root"
  group "root"
  mode "0755"
  recursive true
  action :create
end

["ruby", "gem", "engineyard-serverside", "ey-services-setup"].each do |executable|
  link "#{resin_path}/#{executable}" do
    to "#{gem_bin_path}/#{executable}"
  end
end
