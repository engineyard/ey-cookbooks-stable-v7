service "nginx" do
  action :restart
  only_if "lsof -n -i :80 -i :443 | grep LISTEN | grep nginx"
end

service "haproxy" do
  action :start
  only_if { ::File.exist?("/etc/init.d/haproxy") }
end

directory "/etc/haproxy/errorfiles" do
  action :create
  owner "root"
  group "root"
  mode "0755"
  recursive true
end

["400.http", "403.http", "408.http", "500.http", "502.http", "503.http", "504.http"].each do |p|
  cookbook_file "/etc/haproxy/errorfiles/#{p}" do
    owner "root"
    group "root"
    mode "0644"
    backup 0
    source "errorfiles/#{p}"
    not_if { ::File.exist?("/etc/haproxy/errorfiles/keep.#{p}") }
  end
end

haproxy_httpchk_path = (app = node.engineyard.apps.detect { |a| a.metadata?(:haproxy_httpchk_path) } and app.metadata?(:haproxy_httpchk_path))
haproxy_httpchk_host = (app = node.engineyard.apps.detect { |a| a.metadata?(:haproxy_httpchk_host) } and app.metadata?(:haproxy_httpchk_host))

unless haproxy_httpchk_path
  app = node.engineyard.apps.detect { |a| a.metadata?(:node_health_check_url) }
  if app
    haproxy_httpchk_path = app.metadata(:node_health_check_url)
    haproxy_httpchk_host = app.vhosts.first.domain_name.empty? ? nil : app.vhosts.first.domain_name
  end
end

managed_template "/etc/haproxy.cfg" do
  owner "root"
  group "root"
  mode "0644"
  source "haproxy.cfg.erb"
  members = node["dna"]["members"] || []
  variables({
    backends: node.engineyard.environment.app_servers,
    app_master_weight: members.size < 51 ? (50 - (members.size - 1)) : 0,
    haproxy_user: node["dna"]["haproxy"]["username"],
    haproxy_pass: node["dna"]["haproxy"]["password"],
    httpchk_host: haproxy_httpchk_host,
    httpchk_path: haproxy_httpchk_path,
  })

  notifies :reload, "service[haproxy]", :delayed
end

link "/etc/haproxy/haproxy.cfg" do
  to "/etc/haproxy.cfg"
end
