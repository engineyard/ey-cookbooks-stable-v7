resource_name :pg_extension
provides :pg_extension
unified_mode true

property :ext_name, [String, Array], required: true
property :db_name, [String, Array], required: true
property :schema_name, String
property :version, String
property :old_version, String
property :use_load, [true, false], default: false # use LOAD instead of CREATE EXTENSION

action :install do
  ext_names = ext_name.is_a?(String) ? [ext_name] : ext_name
  db_names = db_name.is_a?(String) ? [db_name] : db_name
  postgres_version = node["postgresql"]["short_version"]

  if node["dna"]["instance_role"][/^(db|solo)/]
    ext_names.each do |ext_name|
      ext_details = node["pg_ext_details"][ext_name] || {}

      # Postgis needs some package work
      include_recipe "ey-postgresql::postgis_build" if ext_name[/^postgis/]

      db_names.each do |db_name|
        # bail with a log message if the extension isn't supported for the active Postgres major version
        if (!ext_details[:min_pg_version].nil? && postgres_version_lt?(ext_details[:min_pg_version])) || (!ext_details[:max_pg_version].nil? && postgres_version_gt?(ext_details[:max_pg_version]))
          Chef::Log.info "PostgreSQL extension #{ext_name} is only supported on versions #{ext_details[:min_pg_version]} #{!ext_details[:max_pg_version].nil? ? 'to ' + ext_details[:max_pg_version].to_s : 'and higher'}. Currently installed version: #{postgres_version}."
          break
        end

        # the main extension/library install bit
        if node["dna"]["instance_role"][/db_master|solo/]
          Chef::Log.info "Installing PostgreSQL extension #{ext_name} to database #{db_name}."
          do_load = ext_details[:use_load].nil? ? (use_load || false) : (ext_details[:use_load] || use_load)
          if do_load
            cmd = "LOAD"
            quoted_ext_name = "'#{ext_name}'"
          else
            cmd = "CREATE EXTENSION IF NOT EXISTS"
            quoted_ext_name = %(\\"#{ext_name}\\")
          end
          execute "Postgresql loading #{do_load ? 'library' : 'extension'} #{ext_name}" do
            command %(psql -U postgres -d #{db_name} -c "#{cmd} #{quoted_ext_name} #{"SCHEMA #{schema_name}" unless schema_name.nil?} #{"VERSION #{version}" unless version.nil?} #{"FROM #{old_version}" unless old_version.nil?};")
          end

          # and a couple follow up commands for Postgis
          if ext_name[/postgis/]
            bash "Updating to correct postgis minor version" do
              # this is essentially a no-op if already on this version.
              code %(
                minor_version=$(apt-cache policy #{node['postgis']['package_name']} | grep -E -o "Installed: ([0-9]+\.[0-9]+\.[0-9]+)" | awk '{print $NF}');
                [[ -n "${minor_version// }" ]] && psql -U postgres -d #{db_name} -c "ALTER EXTENSION postgis UPDATE TO '$minor_version';" || echo "Postgis version not found. Is it installed?"
              )
            end

            execute "Grant permissions to the #{node.engineyard.environment.ssh_username} user on the geometry_columns schema" do
              command %(psql -U postgres -d #{db_name} -c "GRANT all on geometry_columns to #{node.engineyard.environment.ssh_username}")
            end

            execute "Grant permissions to the #{node.engineyard.environment.ssh_username} user on the spatial_ref_sys schema" do
              command %(psql -U postgres -d #{db_name} -c "GRANT all on spatial_ref_sys to #{node.engineyard.environment.ssh_username}")
            end
          end
        end

        # these needs some configuration
        include_recipe "ey-postgresql::auto_explain" if ext_name == "auto_explain"
        include_recipe "ey-postgresql::pg_stat_statements" if ext_name == "pg_stat_statements"
      end
    end
  end
end
