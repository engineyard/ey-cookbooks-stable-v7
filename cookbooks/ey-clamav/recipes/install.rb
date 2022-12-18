clamav = node["clamav"]

apt_package "clamav-daemon" do
  version clamav["version"]
  action :install
end

systemd_unit "clamav-daemon" do
  action :start
end

systemd_unit "clamav-daemon" do
  action :enable
end
