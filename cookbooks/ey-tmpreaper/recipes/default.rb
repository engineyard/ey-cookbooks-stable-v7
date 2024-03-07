#
# Cookbook:: ey-tmpreaper
# Recipe:: default
#

# Fetch environment variables or set defaults
tmpreaper_time = fetch_env_var(node,'EY_TMPREAPER_TIME', '7d') # Default to cleaning files older than 7 days

ey_cloud_report "tmpreaper" do
  message "Installing tmpreaper"
end

package "tmpreaper" do
  action :install
end

template "/etc/tmpreaper.conf" do
  owner "root"
  group "root"
  mode "0644"
  source "tmpreaper.conf.erb"
   variables(
    time: tmpreaper_time
   )
end

ey_cloud_report "tmpreaper" do
  message "tmpreaper installed"
end

