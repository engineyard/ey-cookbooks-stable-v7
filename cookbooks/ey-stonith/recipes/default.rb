if ["app_master", "app"].include?(node["dna"]["instance_role"])
  file "/etc/stonith.yml" do
    owner "root"
    group "root"
    mode "0644"
    content YAML.dump(node.engineyard.instance.stonith_config.to_hash)
  end

  cookbook_file "/etc/systemd/system/stonith.service" do
    owner "root"
    group "root"
    mode "0644"
    source "stonith.service"
    notifies :run, "execute[reload-systemd]", :immediately
    notifies :restart, "service[stonith]", :delayed
  end

  logrotate "ey-stonith" do
    files "/var/log/stonith.log"
    copy_then_truncate true
  end

  service "stonith" do
    provider Chef::Provider::Service::Systemd
    action [:start, :enable]
  end
end