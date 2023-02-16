ey_cloud_report "db admin tools" do
  message "processing db tools started"
end

case node.engineyard.environment["db_stack_name"]
when /mysql/
  include_recipe "ey-db_admin_tools::mysql"
when /postgres/
  include_recipe "ey-db_admin_tools::postgres"
end

ey_cloud_report "db admin tools" do
  message "processing db tools finished"
end
