node.engineyard.apps.each do |app|
  dbhost = (node["dna"]["db_host"] == "localhost" ? "localhost" : "%")

  short_version = node["mysql"]["short_version"]
  config_postfix = if short_version == "8.0"
                     "80"
                   else
                     ""
                   end

  template "/tmp/create.#{app.database_name}.sql" do
    owner "root"
    group "root"
    mode "644"
    source "create#{config_postfix}.sql.erb"
    variables({
      dbuser: app.database_username,
      dbpass: app.database_password,
      dbname: app.database_name,
      dbhost: dbhost,
    })
  end

  execute "remove-database-file-for-#{app.database_name}" do
    command %(rm /tmp/create.#{app.database_name}.sql)
    action :nothing
  end

  execute "create-database-for-#{app.database_name}" do
    command %(mysql -u #{node.engineyard.environment['db_admin_username']} -p'#{node.engineyard.environment['db_admin_password']}' < /tmp/create.#{app.database_name}.sql)
    notifies :run, "execute[remove-database-file-for-#{app.database_name}]"
  end
end
