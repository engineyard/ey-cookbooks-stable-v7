(node["dna"]["applications"] || []).each do |app_name, _|
  directory "/var/log/engineyard/apps/#{app_name}" do
    owner node["owner_name"]
    group node["owner_name"]
    mode "0755"
    recursive true
  end

  directory "create shared directory to symlink log" do
    path "/data/#{app_name}/shared"
    owner node["owner_name"]
    group node["owner_name"]
    mode "0755"
    recursive true
  end

  link "/data/#{app_name}/shared/log" do
    to "/var/log/engineyard/apps/#{app_name}"
    owner node["owner_name"]
    group node["owner_name"]
  end
end

logrotate "application-logs" do
  files "/var/log/engineyard/apps/*/*.log"
  copy_then_truncate true
end

existing_apps = `ls /var/log/engineyard/apps/`.split

existing_apps.each do |existing_app|
  unless node["dna"]["applications"].include? existing_app
    execute "Remove files of detached apps" do
      command %(rm -rf /var/log/engineyard/apps/#{existing_app})
      not_if { ::Dir.glob("/data/#{existing_app}/release*").nil? }
    end
  end
end
