default["nginx"]["action"] = node.engineyard.metadata(:nginx_action, :restart)
default["nginx"]["http2"] = fetch_env_var(node, "EY_HTTP2_ENABLED") =~ /^TRUE$/i
default["nginx"]["systemd_mask"] = ["app_master", "app", "solo"].include?(node["dna"]["instance_role"]) ? false : true
default["nginx"]["behind_proxy"] = true
default["nginx"]["nginx_haproxy_http_port"] = 8091
default["nginx"]["nginx_haproxy_https_port"] = 8092
default["nginx"]["nginx_xlb_http_port"] = 8081
default["nginx"]["nginx_xlb_https_port"] = 8082
default["nginx"]["letsencrypt"] = fetch_env_var(node, "EY_LETSENCRYPT_ENABLED")