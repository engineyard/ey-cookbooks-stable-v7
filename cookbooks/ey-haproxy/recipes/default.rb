ey_cloud_report "haproxy" do
  message "processing haproxy started"
end

include_recipe "ey-haproxy::configure"
include_recipe "ey-haproxy::install"

ey_cloud_report "haproxy" do
  message "processing haproxy finished"
end