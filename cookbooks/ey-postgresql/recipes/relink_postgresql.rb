link_file = "/etc/engineyard/.postgresql-#{node['postgresql']['short_version']}.ey-resin-pg-re-linked"

file link_file do
  owner "root"
  group "root"
  mode "644"
  action :nothing
end

execute "re-link-postgresql" do
  command "/usr/local/ey_resin/ruby/bin/gem install pg -v 0.9 --no-document"
  notifies :touch, "file[#{link_file}]", :immediately
  not_if { ::File.exist?(link_file) }
end
