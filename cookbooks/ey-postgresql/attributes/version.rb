case attribute["dna"]["engineyard"]["environment"]["db_stack_name"]
when "postgres9_5", "aurora-postgresql9_5"
  default["postgresql"]["latest_version"] = "9.5.25"
  default["postgresql"]["short_version"] = "9.5"
when "postgres9_6", "aurora-postgresql9_6"
  default["postgresql"]["latest_version"] = "9.6.24"
  default["postgresql"]["short_version"] = "9.6"
when "postgres10", "aurora-postgresql10"
  default["postgresql"]["latest_version"] = "10.20"
  default["postgresql"]["short_version"] = "10"
when "postgres11", "aurora-postgresql11"
  default["postgresql"]["latest_version"] = "11.16"
  default["postgresql"]["short_version"] = "11"
when "postgres12", "aurora-postgresql12"
  default["postgresql"]["latest_version"] = "12.13"
  default["postgresql"]["short_version"] = "12"
when "postgres13", "aurora-postgresql13"
  default["postgresql"]["latest_version"] = "13.9"
  default["postgresql"]["short_version"] = "13"
when "postgres14", "aurora-postgresql14"
  default["postgresql"]["latest_version"] = "14.6"
  default["postgresql"]["short_version"] = "14"
end

unless fetch_env_var(node, "EY_POSTGRES_VERSION").nil?
  default["postgresql"]["latest_version"] = fetch_env_var(node, "EY_POSTGRES_VERSION")
  default["postgresql"]["short_version"] = fetch_env_var(node, "EY_POSTGRES_VERSION").split(".")[0]
end

default["postgresql"]["datadir"] = "/db/postgresql/#{node['postgresql']['short_version']}/data/"
default["postgresql"]["ssldir"] = "/db/postgresql/#{node['postgresql']['short_version']}/ssl/"
default["postgresql"]["dbroot"] = "/db/postgresql/"
default["postgresql"]["owner"] = "postgres"
default["postgresql"]["pgbindir"] = "/usr/lib/postgresql/#{node['postgresql']['short_version']}/bin/"

# postgis
default["postgis"]["version"] = "2.5"
default["postgis"]["package_name"] = "postgresql-#{default['postgresql']['short_version']}-postgis-#{default['postgis']['version']}"
