provides :createdb
unified_mode true
property :user, String, default: "postgres"
property :name, String, default: "deploy"
property :owner, String, default: "deploy"

default_action :createdb_action

action :createdb_action do
  if ["solo", "db_master"].include?(node["dna"]["instance_role"])
    execute "create database for #{new_resource.name}" do
      command %(psql -U postgres postgres -c \"CREATE DATABASE #{new_resource.name} OWNER #{new_resource.owner}\")
      not_if %(psql -U postgres -t -c "select datname from pg_database where datname = '#{new_resource.name}';" | grep #{new_resource.name})
    end
  end
end