#
# Cookbook:: dr_replication
# Recipe:: postgres_master_configuration
#

# Add 127.0.0.1/32 to pg_hba.conf file and custom_pg_hba.conf file to persist changes
bash 'update-pg-hba-conf' do
  code "echo 'host    replication     postgres        127.0.0.1/32              md5' >> /db/postgresql/#{node['postgresql']['short_version']}/data/pg_hba.conf"
  not_if "grep 'host    replication     postgres        127.0.0.1/32              md5' /db/postgresql/#{node['postgresql']['short_version']}/data/pg_hba.conf"
end

bash 'update-custom-pg-hba-conf' do
  code "echo 'host    replication     postgres        127.0.0.1/32              md5' >> /db/postgresql/#{node['postgresql']['short_version']}/custom_pg_hba.conf"
  not_if "grep 'host    replication     postgres        127.0.0.1/32              md5' /db/postgresql/#{node['postgresql']['short_version']}/custom_pg_hba.conf"
end

# Add localhost to pg_hba.conf file and custom_pg_hba.conf file to persist changes
bash 'update-pg-hba-conf-localhost' do
  code "echo 'host    replication     postgres        localhost              md5' >> /db/postgresql/#{node['postgresql']['short_version']}/data/pg_hba.conf"
  not_if "grep 'host    replication     postgres        localhost              md5' /db/postgresql/#{node['postgresql']['short_version']}/data/pg_hba.conf"
end

bash 'update-custom-pg-hba-conf-localhost' do
  code "echo 'host    replication     postgres        localhost              md5' >> /db/postgresql/#{node['postgresql']['short_version']}/custom_pg_hba.conf"
  not_if "grep 'host    replication     postgres        localhost              md5' /db/postgresql/#{node['postgresql']['short_version']}/custom_pg_hba.conf"
end

bash 'reload-postgres-config' do
  code "su - postgres -c 'pg_ctl reload -D /db/postgresql/#{node['postgresql']['short_version']}/data/'"
end
