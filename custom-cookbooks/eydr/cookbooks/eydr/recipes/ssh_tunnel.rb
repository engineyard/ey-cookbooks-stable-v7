#
# Cookbook:: eydr
# Recipe:: ssh_tunnel
#

case node.engineyard.environment['db_stack_name']
when /mysql(.*)/
  connect_port = 13306
  forward_port = 3306
when /postgres(.*)/
  connect_port = 5433
  forward_port = 5432
end

tunnel_name = 'ssh_tunnel'

# fill in missing information below
tunnel_vars = {
  # the host hostname (an IP will work) to ssh to
  ssh_hostname: node['dr_replication'][node['dna']['environment']['framework_env']]['master']['public_hostname'],
  # only change this if using a non-default ssh port on the destination host,
  # such as when connecting through a gateway
  ssh_port: 22,
  # the system user account to use when logging into the destination host
  ssh_user: node['owner_name'],
  # the path to the private key on the instance the tunnel is from
  ssh_private_key: "/home/#{node['owner_name']}/.ssh/eydr_key",
  # the path to the public key on the instance the tunnel is from
  ssh_public_key: "/home/#{node['owner_name']}/.ssh/eydr_key.pub",
  # the port that will be being forwarded
  connect_port: connect_port,
  # the host on the remote side (or local side for a reverse tunnel)
  # that the :connect_port will be forwarded to
  forward_host: 'localhost',
  # the port on :forward_host that :connect_port will be forwarded to
  forward_port: forward_port,
  # valid values: FWD, REV, DUAL. Determines what kind of tunnel(s) to create
  # DUAL means create both a forward and reverse tunnel
  tunnel_direction: 'DUAL',
  # the path to the ssh executable to use when making the ssh connection
  ssh_cmd: '/usr/bin/ssh',
  # whether or not to use StrictHostKeyChecking when making the ssh connection
  skip_hostkey_auth: false,
  # the path to the known hosts file with the public key of the remote server
  # only set if :skip_hostkey_auth is set to false
  # note that if :skip_hostkey_auth is set to true then you need to make a
  # manual connection to the remote host *before* deploying this recipe
  # and use the path to the known_hosts file that the remote host's public
  # key is written to here.  It's also even better to copy that key entry to
  # a file somewhere on an EBS volume and use that file's path here to ensure
  # that it won't be wiped after an instance restart (terminate and rebuild)
  ssh_known_hosts: '',
}

# set this to match on the node[:instance_role] of the instance the tunnel
# should be set up on
if ['solo', 'db_master'].include?(node['dna']['instance_role'])

  template "/etc/init.d/#{tunnel_name}" do
    source 'ssh_tunnel.initd.erb'
    owner 'root'
    group 'root'
    mode '0755'
    variables(tunnel_vars)
  end

  template "/etc/monit.d/#{tunnel_name}.monitrc" do
    source 'ssh_tunnel.monitrc.erb'
    owner node['owner_name']
    group node['owner_name']
    mode '0644'
    variables(tunnel_vars)
  end

  execute 'monit quit'

end
