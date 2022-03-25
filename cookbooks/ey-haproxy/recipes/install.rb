package "haproxy" do
  action :upgrade
end

service "haproxy" do
  action :enable
  supports status: true, restart: true, start: true
  subscribes :restart, "package[haproxy]", :immediately
end
