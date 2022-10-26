ey_cloud_report "Fail2Ban" do
  message "Installing Fail2Ban"
end

# Install Fail2ban on all instances
# Install Fail2ban only on selected instances

if node['fail2ban']['is_fail2ban_enabled_instance']
  package 'fail2ban' do
    action :install
  end

  template "/etc/fail2ban/fail2ban.conf" do
    owner 'root'
    group 'root'
    mode 0644
    source "fail2ban.conf.erb"
    variables({
      loglevel: node['fail2ban']['loglevel'],
      logtarget: node['fail2ban']['logtarget'],
      socket: node['fail2ban']['socket'],
      pidfile: node['fail2ban']['pidfile']
    })
  end

  include_recipe "ey-fail2ban::service"
  include_recipe "ey-fail2ban::jails"
end