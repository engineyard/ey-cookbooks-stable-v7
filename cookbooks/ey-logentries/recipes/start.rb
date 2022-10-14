# Restart the le agent
service "logentries" do
  action [:enable, :restart]
end
