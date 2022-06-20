recipe = self
node.engineyard.apps.each do |app|
  template "/data/#{app.name}/shared/config/env" do
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode "644"
    variables({
      app: app.name,
      user: node.engineyard.environment.ssh_username,
      type: app.app_type,
      app_type: app.app_type,
      framework_env: node["dna"]["environment"]["framework_env"],
      ruby_bin_path: "/opt/rubies/#{node['ruby']['name']}-#{node['ruby']['version']}/bin",
    })
    source "env.erb"
  end

  template "/engineyard/bin/app_#{app.name}" do
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode "777"
    source "unicorn.initd.sh.erb"
    variables({
      app: app.name,
      app_type: app.app_type,
      user: node.engineyard.environment.ssh_username,
      group: node.engineyard.environment.ssh_username,
    })
  end

  file "/etc/init.d/unicorn_#{app.name}" do
    action :delete
    backup 0

    not_if "test -h /etc/init.d/unicorn_#{app.name}"
  end

  link "/etc/init.d/unicorn_#{app.name}" do
    to "/engineyard/bin/app_#{app.name}"
  end

  template "/data/#{app.name}/shared/config/unicorn.rb" do
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode "644"
    action :create
    variables({
      unicorn_instance_count: [recipe.get_pool_size / node["dna"]["applications"].size, 1].max,
      app: app.name,
      type: app.app_type,
      user: node.engineyard.environment.ssh_username,
    })
    source "unicorn.rb.erb"
  end

  term_conds = app_server_get_worker_termination_conditions(app)

  managed_template "/lib/systemd/system/unicorn_#{app.name}.service" do
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode "600"
    source "unicorn.service.erb"
    variables({
      app: app.name,
      environment: node["dna"]["environment"]["framework_env"]
    })
    backup 0

    notifies :run, "execute[reload-monit]", :delayed
  end

  # cleanup extra unicorn workers
  bash "cleanup extra unicorn workers" do
    code lazy {
      <<-EOH
        for pidfile in /var/run/engineyard/unicorn_worker_#{app.name}_*.pid; do
          [[ $(echo "${pidfile}" | egrep -o '([0-9]+)' | tail -n 1) -gt #{recipe.get_pool_size - 1} ]] && kill -QUIT $(cat $pidfile) || true
        done
      EOH
    }
  end
end

