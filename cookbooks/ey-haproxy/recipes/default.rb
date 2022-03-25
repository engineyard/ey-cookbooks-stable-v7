ey_cloud_report "haproxy" do
  message "processing haproxy"
end

include_recipe "ey-haproxy::configure"
include_recipe "ey-haproxy::install"
