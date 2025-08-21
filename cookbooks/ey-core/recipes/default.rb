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
    sed -i.bak 's|http://.*.ec2.archive.ubuntu.com/ubuntu/|http://archive.ubuntu.com/ubuntu/|g' /etc/apt/sources.list &&
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - &&
    sed -i.bak 's|http://apt.postgresql.org/pub/repos/apt|http://apt-archive.postgresql.org/pub/repos/apt|g' /etc/apt/sources.list.d/posgresql.list
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
