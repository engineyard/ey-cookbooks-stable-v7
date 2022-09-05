class Chef::Recipe
  include NewrelicHelpers
end

apt_repository "newrelic-infra" do
  uri "https://download.newrelic.com/infrastructure_agent/linux/apt"
  distribution "#{`lsb_release -cs`.strip}"
  components ["main"]
  key "https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg"
end.run_action(:add)

license_key = if node["newrelic_infra"]["use_newrelic_addon"]
                newrelic_license_key
              else
                node["newrelic_infra"]["license_key"]
              end

display_name = node["newrelic_infra"]["display_name"]

template "/etc/newrelic-infra.yml" do
  source "newrelic-infra.yml.erb"
  owner "root"
  group "root"
  mode "0600"
  backup false
  variables({
    license_key: license_key,
    display_name: display_name,
  })
end

apt_update

package "newrelic-infra" do
  action :install
end
