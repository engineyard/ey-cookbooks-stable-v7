postgres_version = node["postgresql"]["short_version"]

if node.engineyard.instance.database_server?
  ey_cloud_report "start postgresql run" do
    message "processing postgresql #{postgres_version}"
  end
  # include_recipe "ey-ebs::default"
  include_recipe "ey-postgresql::client_config"
  include_recipe "ey-postgresql::server_install"
  include_recipe "ey-postgresql::server_configure"
  include_recipe "ey-postgresql::monitoring"
  include_recipe "ey-postgresql::relink_postgresql"
  ey_cloud_report "stop postgresql run" do
    message "processing postgresql #{postgres_version} finished"
  end
end
if ["app_master", "app", "util"].include?(node["dna"]["instance_role"])
  ey_cloud_report "start postgresql run" do
    message "processing postgresql #{postgres_version}"
  end
  include_recipe "ey-postgresql::client_config"
  include_recipe "ey-postgresql::server_install"
  include_recipe "ey-postgresql::relink_postgresql"
  ey_cloud_report "stop postgresql run" do
    message "processing postgresql #{postgres_version} finished"
  end
end

if (db_host_is_rds? && node["dna"]["instance_role"] == "app_master") || (!db_host_is_rds? && ["solo", "db_master", "eylocal"].include?(node["dna"]["instance_role"]))
  include_recipe "ey-postgresql::setup_app_users_dbs"
end
