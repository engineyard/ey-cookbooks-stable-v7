node.engineyard.apps.each_with_index do |app, _index|
  php_webroot = node.engineyard.environment.apps.first["components"].find { |component| component["key"] == "app_metadata" }["php_webroot"]

  files = app.https? ? ["/data/nginx/servers/#{app.name}.conf", "/data/nginx/servers/#{app.name}.ssl.conf"] : ["/data/nginx/servers/#{app.name}.conf"]

  files.each_with_index do |file, count|
    managed_template "#{file}" do
      owner node["owner_name"]
      group node["owner_name"]
      mode "0644"
      source "fpm-server.conf.erb"
      variables(
        webroot: php_webroot,
        vhost: app.vhosts.first,
        env_name: node.engineyard.environment["name"],
        haproxy_nginx_port: !(count == 0) ? node["nginx"]["nginx_haproxy_https_port"] : node["nginx"]["nginx_haproxy_http_port"],
        xlb_nginx_port: !(count == 0) ? node["nginx"]["nginx_xlb_https_port"] : node["nginx"]["nginx_xlb_http_port"],
        http2: node["nginx"]["http2"],
        ssl: !(count == 0)
      )
      notifies node["nginx"]["action"], "service[nginx]", :delayed
    end
  end
end