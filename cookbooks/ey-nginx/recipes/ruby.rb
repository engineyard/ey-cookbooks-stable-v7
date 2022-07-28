is_app_master = ["app_master", "solo"].include?(node["dna"]["instance_role"]) || false

# app_base_port = node["passenger5"]["port"].to_i

# Temp

# To be imporved at a later date by getting variables from env_vars and node values of puma rather than setting them multiple times
if node.stack.match(/puma/)
  base_port = 8000
  stepping = 200
end

node.engineyard.apps.each_with_index do |app, index|
  if node.stack.match(/puma/)
    app_base_port = base_port + (stepping * index)
    workers = [(1.0 * get_pool_size() / node["dna"]["applications"].size).round, 1].max
    ports = (app_base_port...(app_base_port + workers)).to_a
  end

  files = app.https? ? ["/data/nginx/servers/#{app.name}.conf", "/data/nginx/servers/#{app.name}.ssl.conf"] : ["/data/nginx/servers/#{app.name}.conf"]
  files.each_with_index do |file, count|
    template "#{file}" do
      owner node["owner_name"]
      group node["owner_name"]
      mode "0644"
      source "nginx_app.conf.erb"
      variables(
        stack: node.stack,
        vhost: app.vhosts.first,
        haproxy_nginx_port: !(count == 0) ? node["nginx"]["nginx_haproxy_https_port"] : node["nginx"]["nginx_haproxy_http_port"],
        xlb_nginx_port: !(count == 0) ? node["nginx"]["nginx_xlb_https_port"] : node["nginx"]["nginx_xlb_http_port"],
        app_instance: is_app_master,
        upstream_port: ports,
        http2: !(count == 0) && node["nginx"]["http2"],
        ssl: !(count == 0)
      )
      notifies :restart, "service[nginx]", :delayed
    end
  end
end