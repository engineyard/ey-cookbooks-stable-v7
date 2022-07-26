execute "extract-chruby" do
  command "tar xzf /tmp/src/chruby-0.3.9.tar.gz && cd chruby-0.3.9 && make install"
  cwd "/tmp/src"
  action :nothing
  not_if "source /usr/local/share/chruby/chruby.sh && chruby --version |grep '0.3.9'"
end

remote_file "/tmp/src/chruby-0.3.9.tar.gz" do
  source "https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz"
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :run, "execute[extract-chruby]", :immediately
  not_if "source /usr/local/share/chruby/chruby.sh && chruby --version |grep '0.3.9'"
end

execute "extract-ruby-install" do
  command "tar xzf /tmp/src/ruby-install-0.8.1.1.tar.gz && cd ruby-install-0.8.1.1 && make install"
  cwd "/tmp/src"
  action :nothing
  not_if "/usr/local/bin/ruby-install --version |grep '0.8.1'"
end

remote_file "/tmp/src/ruby-install-0.8.1.1.tar.gz" do
  source "https://github.com/engineyard/ruby-install/archive/v0.8.1.1.tar.gz"
  owner "root"
  group "root"
  mode "0755"
  action :create
  notifies :run, "execute[extract-ruby-install]", :immediately
  not_if "/usr/local/bin/ruby-install --version |grep '0.8.1'"
end

ruby_name = node["ruby"]["name"]
ruby_version = node["ruby"]["version"]
ruby = "#{ruby_name}-#{ruby_version}"
log "Setting Ruby version to #{ruby}"

template "/etc/profile.d/chruby.sh" do
  source "chruby.sh.erb"
  owner "root"
  group "root"
  mode "0644"
  variables ruby: ruby
  action :create
end

include_recipe "ey-ruby::dependencies"

bash "install ruby" do
  code <<-EOH
    source /usr/local/share/chruby/chruby.sh
    if [[ ! $(chruby #{ruby} 2>&1 >/dev/null) ]]; then
      echo "Ruby #{ruby} is already installed. Skipping Ruby installation"
    else
      echo "Installing Ruby #{ruby}"
      mkdir -p /opt/rubies
      chown -R #{node['owner_name']}:#{node['owner_name']} /opt/rubies
      DEBIAN_FRONTEND=noninteractive sudo -u #{node['owner_name']} \
        ruby-install --no-install-deps -r /opt/rubies #{ruby_name} #{ruby_version}
    fi
  EOH
end

execute "chown /opt/rubies" do
  command "chown -R #{node['owner_name']}:#{node['owner_name']} /opt/rubies"
end

ruby_block "add ruby path during chef run" do
  block { ENV["PATH"] = "/opt/rubies/#{ruby}/bin:#{ENV['PATH']}" }
end

# Add gemrc for the root user
cookbook_file "/root/.gemrc" do
  source "gemrc"
end

["ruby", "gem", "bundler", "bundle"].each do |binary|
  link "/usr/bin/#{binary}" do
    to "/opt/rubies/#{ruby}/bin/#{binary}"
    only_if { ::File.exist?("/opt/rubies/#{ruby}/bin") }
    action :create
  end
end

include_recipe "ey-ruby::rubygems"
