execute "reload-systemd" do
  command "systemctl daemon-reload"
  action :nothing
end

execute "reexecute systemd" do
  command "systemctl daemon-reexec"
  action :nothing
end

case node["dna"]["instance_role"]
when "app", "app_master"
  include_recipe "ey-stonith"
end