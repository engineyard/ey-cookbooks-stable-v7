include_recipe "ey-prechef"

execute "reload-systemd" do
  command "systemctl daemon-reload"
  action :nothing
end

execute "reload-monit" do
  command "monit reload"
  action :nothing
end

execute "update-apt-sources" do
  command <<-EOH
    cp /etc/apt/sources.list /etc/apt/sources.list.bak &&
    sed -i 's|http://.*.ec2.archive.ubuntu.com/ubuntu/|http://archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list &&
    apt-get update
  EOH
  action :run
end

apt_update

package "openssl"

package "run-one" # Makes the run-one binary accessible across system, similar to lockrun in previous stack

include_recipe "ey-sysctl::tune"
include_recipe "ey-core::swap"
include_recipe "ey-instance-api"
include_recipe "ey-syslog-ng"
include_recipe "ey-timezones"
include_recipe "ey-logrotate"
include_recipe "ey-hosts"
include_recipe "ey-core::sshd"
include_recipe "ey-unattended-upgrades"
