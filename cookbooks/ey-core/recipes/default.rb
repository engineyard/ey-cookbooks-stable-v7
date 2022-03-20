execute "reload-systemd" do
  command "systemctl daemon-reload"
  action :nothing
end

execute "reload-monit" do
  command "monit reload"
  action :nothing
end

apt_update

include_recipe "ey-sysctl::tune"
include_recipe "ey-core::swap"

include_recipe "ey-ntp"

include_recipe "ey-core::sshd"
include_recipe "ey-unattended-upgrades"