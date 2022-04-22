existing_apps = `ls /var/log/engineyard/apps/`.split

existing_apps.each do |existing_app|
  unless node["dna"]["applications"].include? existing_app
    execute "Remove files of detached apps" do
      command %(rm -rf /data/#{existing_app})
      not_if { ::Dir.glob("/data/#{existing_app}/release*").nil? }
    end
  end
end
