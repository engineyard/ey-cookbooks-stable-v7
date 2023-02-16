ey_cloud_report "mysql monitoring" do
  message "processing mysql monitoring started"
end

template "/engineyard/bin/check_mysql.sh" do
  source "check_mysql.sh.erb"
  backup 0
  owner "mysql"
  group "mysql"
  mode "751"
  variables({
    dbpass: node.engineyard.environment["db_admin_password"],
  })
end

ey_cloud_report "mysql monitoring" do
  message "processing mysql monitoring finished"
end
