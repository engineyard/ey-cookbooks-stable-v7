include_recipe "ey-nginx::install"

Chef::Log.info "instance role: #{node['dna']['instance_role']}"

service "nginx" do
  provider Chef::Provider::Service::Systemd
  action :nothing
  supports restart: true, status: true, reload: true
  only_if { ["solo", "app", "app_master"].include?(node["dna"]["instance_role"]) }
end

workers = get_pool_size
if node.stack.match(/puma/)
  workers = [(1.0 * get_pool_size() / node["dna"]["applications"].size).round, 1].max
end

managed_template "/data/nginx/nginx.conf" do
  owner node["owner_name"]
  group node["owner_name"]
  mode "0644"
  source "nginx-plusplus.conf.erb"
  variables(
    user: node["owner_name"],
    pool_size: workers,
    behind_proxy: node["nginx"]["behind_proxy"]
  )
  notifies node["nginx"]["action"], "service[nginx]", :delayed
end

directory "/data/nginx/ssl" do
  owner node["owner_name"]
  group node["owner_name"]
  mode "0775"
end

file "/data/nginx/http-custom.conf" do
  action :create_if_missing
  owner node["owner_name"]
  group node["owner_name"]
  mode "0644"
end

managed_template "/data/nginx/common/proxy.conf" do
  owner node["owner_name"]
  group node["owner_name"]
  mode "0644"
  source "common.proxy.conf.erb"
  notifies node["nginx"]["action"], "service[nginx]", :delayed
end

managed_template "/data/nginx/common/servers.conf" do
  owner node["owner_name"]
  group node["owner_name"]
  mode "0644"
  source "common.servers.conf.erb"
  notifies node["nginx"]["action"], "service[nginx]", :delayed
end

file "/data/nginx/servers/default.conf" do
  owner node["owner_name"]
  group node["owner_name"]
  mode "0644"
  notifies node["nginx"]["action"], "service[nginx]", :delayed
end

# Issue https://github.com/engineyard/ey-cookbooks-dev-v6/issues/11 needs to be fixed for that to work
(node["dna"]["removed_applications"] || []).each do |app|
  execute "remove-old-vhosts-for-#{app}" do
    command "rm -rf /data/nginx/servers/#{app}*"
    notifies node["nginx"]["action"], "service[nginx]", :delayed
  end
end

managed_template "/data/nginx/common/fcgi.conf" do
  owner node["owner_name"]
  group node["owner_name"]
  mode "0644"
  source "common.fcgi.conf.erb"
  notifies node["nginx"]["action"], "service[nginx]", :delayed
end

node.engineyard.apps.each_with_index do |app, _index|
  directory "/data/nginx/servers/#{app.name}" do
    owner node["owner_name"]
    group node["owner_name"]
    mode "0775"
  end

  managed_template "/etc/nginx/servers/#{app.name}/additional_server_blocks.customer" do
    owner node["owner_name"]
    group node["owner_name"]
    mode "0644"
    variables({
      app_name: app.name,
      server_name: (app.vhosts.first.domain_name.empty? || app.vhosts.first.domain_name == "_") ? "www.domain.com" : app.vhosts.first.domain_name,
    })
    source "additional_server_blocks.customer.erb"
    not_if { ::File.exist?("/etc/nginx/servers/#{app.name}/additional_server_blocks.customer") }
  end

  managed_template "/etc/nginx/servers/#{app.name}/additional_location_blocks.customer" do
    owner node["owner_name"]
    group node["owner_name"]
    mode "0644"
    source "additional_location_blocks.customer.erb"
    not_if { ::File.exist?("/etc/nginx/servers/#{app.name}/additional_location_blocks.customer") }
  end

  directory "/data/nginx/ssl/#{app.name}" do
    owner node["owner_name"]
    group node["owner_name"]
    mode "0775"
  end

  file "/data/nginx/servers/#{app.name}/custom.conf" do
    action :create_if_missing
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode "0644"
  end

  managed_template "/data/nginx/ssl/#{app.name}/dhparam.#{app.name}.pem" do
    owner node["owner_name"]
    group node["owner_name"]
    mode "0600"
    source "dhparam.erb"
    variables(
      dhparam: app.metadata("dh_key")
    )
    notifies node["nginx"]["action"], "service[nginx]", :delayed
    only_if { app.metadata("dh_key", nil) }
  end

  managed_template "/data/nginx/servers/#{app.name}.users" do
    owner node["owner_name"]
    group node["owner_name"]
    mode "0644"
    source "users.erb"
    variables(
      application: app
    )
    notifies node["nginx"]["action"], "service[nginx]", :delayed
  end

  managed_template "/etc/nginx/listen_http.port" do
    owner node["owner_name"]
    group node["owner_name"]
    mode "0644"
    source "listen-http.erb"
    variables({
      http_bind_port: node["nginx"]["nginx_haproxy_http_port"],
    })
    notifies node["nginx"]["action"], "service[nginx]", :delayed
  end

  # if there is an ssl vhost
  file "/data/nginx/servers/#{app.name}/custom.ssl.conf" do
    action :create_if_missing
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode "0644"
    only_if { app.https? }
  end

  managed_template "/etc/nginx/servers/#{app.name}/additional_server_blocks.ssl.customer" do
    owner node["owner_name"]
    group node["owner_name"]
    mode "0644"
    variables({
      app_name: app.name,
      server_name: (app.vhosts.first.domain_name.empty? || app.vhosts.first.domain_name == "_") ? "www.domain.com" : app.vhosts.first.domain_name,
    })
    source "additional_server_blocks.ssl.customer.erb"
    not_if { ::File.exist?("/etc/nginx/servers/#{app.name}/additional_server_blocks.ssl.customer") }
  end

  managed_template "/etc/nginx/servers/#{app.name}/additional_location_blocks.ssl.customer" do
    owner node["owner_name"]
    group node["owner_name"]
    mode "0644"
    source "additional_location_blocks.ssl.customer.erb"
    not_if { ::File.exist?("/etc/nginx/servers/#{app.name}/additional_location_blocks.ssl.customer") }
  end
end

existing_apps = `cd /data/nginx/servers && ls -d */  |rev | cut -c 2- | rev`.split

existing_apps.each do |existing_app|
  unless node["dna"]["applications"].include? existing_app
    execute "Remove SSL files of detached apps" do
      command %(rm -rf /data/nginx/ssl/#{existing_app})
    end
    execute "Remove nginx config files of detached apps" do
      command %(rm -rf /data/nginx/servers/#{existing_app} && rm -rf /data/nginx/servers/#{existing_app}.*)
    end
  end
end

if node.engineyard.environment.ruby?
  include_recipe "ey-nginx::ruby"
elsif node.stack == "php_fpm"
  include_recipe "ey-nginx::php"
end

service "start nginx" do
  service_name "nginx"
  provider Chef::Provider::Service::Systemd
  supports status: true, restart: true, reload: true
  action [:start, :enable]
  only_if { ["solo", "app", "app_master"].include?(node["dna"]["instance_role"]) }
end
