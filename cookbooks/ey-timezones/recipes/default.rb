zonepath = "/usr/share/zoneinfo/"
zone = "#{node.engineyard.environment['timezone']}"

if !::File.exist?(File.join(zonepath, zone)) && zone != "" && !zone.nil?
  raise "Timezone '#{zone}' not recognized."
end

service "cron"

link "/etc/localtime" do
  to "#{File.join(zonepath, zone)}"
  notifies :restart, "service[cron]", :delayed
  	notifies :restart, "service[syslog-ng]", :delayed
  if node.engineyard.instance.app_server?
  	notifies :restart, "service[nginx]", :delayed
  end
  only_if { ::File.exist?(File.join(zonepath, zone)) && zone != "" && !zone.nil? }
end
