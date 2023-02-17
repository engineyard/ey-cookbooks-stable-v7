ey_cloud_report "puma" do
  message "processing puma started"
end

workers = [(1.0 * get_pool_size() / node["dna"]["applications"].size).round, 1].max
threads = 5

node.engineyard.apps.each_with_index do |app, index|
  port = (8000 + (index * 200))
  app_path      = "/data/#{app.name}"
  deploy_file   = "#{app_path}/current/REVISION"
  log_file      = "#{app_path}/shared/log/puma.log"
  ssh_username  = node.engineyard.environment.ssh_username
  framework_env = node["dna"]["environment"]["framework_env"]

  directory "#{app.name} nginx app directory for puma" do
    path "/data/nginx/servers/#{app.name}"
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode "0775"
  end

  file "#{app.name} custom.conf for puma" do
    path "/data/nginx/servers/#{app.name}/custom.conf"
    action :create_if_missing
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode "0644"
  end

  directory "/var/run/engineyard/#{app.name}" do
    owner ssh_username
    group ssh_username
    mode "0755"
    recursive true
  end

  template "/data/#{app.name}/shared/config/env" do
    source "env.erb"
    backup 0
    owner ssh_username
    group ssh_username
    mode "0755"
    variables(app_name: app.name,
              user: ssh_username,
              deploy_file: deploy_file,
              framework_env: framework_env,
              baseport: port,
              workers: workers,
              threads: threads)
  end

  service "puma_#{app.name}.service" do
    provider Chef::Provider::Service::Systemd
    action :nothing
  end

  managed_template "/engineyard/bin/app_#{app.name}" do
    source  "app_control.erb"
    owner   ssh_username
    group   ssh_username
    mode    "0755"
    backup  0
    variables(app_name: app.name,
              app_dir: "#{app_path}/current",
              deploy_file: deploy_file,
              shared_path: "#{app_path}/shared",
              cloudvar: ::File.exist?("/data/#{app.name}/shared/config/env.cloud"),
              customvar: ::File.exist?("/data/#{app.name}/shared/config/env.custom"),
              framework_env: framework_env)
  end

  logrotate "puma_#{app.name}" do
    files log_file
    copy_then_truncate
  end

  managed_template "/lib/systemd/system/puma_#{app.name}.service" do
    source "puma.service.erb"
    owner "root"
    group "root"
    mode "0666"
    backup 0
    variables(app: app.name,
              framework_env: framework_env,
              app_memory_limit: (app_server_get_worker_memory_size(app).to_i * workers),
              username: ssh_username,
              workers: workers,
              threads: threads,
              port: port,
              systemctlvar: ::File.exist?("/data/#{app.name}/shared/config/env.systemctl"),
              customvar: ::File.exist?("/data/#{app.name}/shared/config/env.custom"))
    notifies :run, "execute[reload-systemd]"
    notifies :enable, "service[puma_#{app.name}.service]", :immediately
  end

  managed_template "/lib/systemd/system/puma_#{app.name}.socket" do
    source "puma.socket.erb"
    owner "root"
    group "root"
    mode "0666"
    backup 0
    variables(app: app.name,
              port: port,
              username: ssh_username)
    notifies :run, "execute[reload-systemd]"
  end
end

ey_cloud_report "puma" do
  message "processing puma finished"
end