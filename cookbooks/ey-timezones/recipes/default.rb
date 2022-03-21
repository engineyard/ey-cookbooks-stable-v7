zonepath = "/usr/share/zoneinfo/"
zone = "#{node.engineyard.environment['timezone']}"

has_nginx = ["solo", "app", "app_master"].include?(node["dna"]["instance_role"])

if !::File.exist?(File.join(zonepath, zone)) && zone != "" && !zone.nil?
  raise "Timezone '#{zone}' not recognized."
end

service "cron"

link "/etc/localtime" do
  to "#{File.join(zonepath, zone)}"
  notifies :restart, "service[cron]", :delayed
  # notifies :restart, "service[syslog-ng]", :delayed
  if has_nginx
  # notifies :restart, "service[nginx]", :delayed
  end
  only_if { ::File.exist?(File.join(zonepath, zone)) && zone != "" && !zone.nil? }
end

# Commented out code requires other recipe to be completed first.