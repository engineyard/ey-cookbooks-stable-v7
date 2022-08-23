ES = node['elasticsearch']
es_version_series = "#{ES['version'][0]}.x"

if ES['is_elasticsearch_instance']
  Chef::Log.info "Setting up the Elasticsearch #{es_version_series} APT repository"

  execute "Add GPG-KEY-elasticsearch" do
    command "wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg --yes"
    action :run
  end 

#  execute "apt-get install apt-transport-https" do
#    command "apt-get install apt-transport-https"
#    action :run
#  end

apt_package 'apt-transport-https' do
  action :install
end

execute "apt-get update for elasticsearch-#{es_version_series}" do
  command "apt-get update"
  action :nothing
end

  execute "Add repository definition for elasticsearch-#{es_version_series}" do
   command "echo 'deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/#{es_version_series}/apt stable main' | sudo tee /etc/apt/sources.list.d/elastic-#{es_version_series}.list "
   action :run 
   notifies :run, "execute[apt-get update for elasticsearch-#{es_version_series}]", :immediately
  end
end