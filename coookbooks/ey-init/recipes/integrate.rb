execute "reload-systemd" do
  command "systemctl daemon-reload"
  action :nothing
end

execute "reexecute systemd" do
  command "systemctl daemon-reexec"
  action :nothing
end