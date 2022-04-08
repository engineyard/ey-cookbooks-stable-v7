# Cookbook:: ey-sysctl
# Recipe:: tune
#
# There are some kernel parameters that default to values which are less than
# ideal for our typical use cases. This recipe is used to tune those defaults.
#

sysctl "fs.file-max" do
  value node["sysctl"]["file_max"]
end

sysctl "fs.inotify.max_user_instances" do 
  value node["sysctl"]["max_user_instances"]
end

sysctl "net.core.somaxconn" do
  value node["sysctl"]["somaxconn"]
end

sysctl "net.core.rmem_max" do
  value node["sysctl"]["rmem_max"]
end

sysctl "net.core.wmem_max" do
  value node["sysctl"]["wmem_max"]
end

sysctl "net.ipv4.tcp_mem" do
  value node["sysctl"]["tcp_mem"]
end

sysctl "net.ipv4.tcp_max_syn_backlog" do
  value node["sysctl"]["max_syn_backlog"]
  only_if "sysctl -a 2>/dev/null | grep 'tcp_syncookies = 1'"
end

sysctl "net.ipv4.tcp_synack_retries" do
  value node["sysctl"]["synack_retries"]
  only_if "sysctl -a 2>/dev/null | grep 'tcp_syncookies = 1'"
end

sysctl "net.core.netdev_max_backlog" do
  value node["sysctl"]["netdev_max_backlog"]
end

sysctl "net.ipv4.tcp_tw_reuse" do
  value node["sysctl"]["tw_reuse"]
end

sysctl "net.ipv4.ip_local_port_range" do
  value node["sysctl"]["local_port_range"]
end

sysctl "net.ipv4.tcp_max_tw_buckets" do
  value node["sysctl"]["max_tw_buckets"]
end

sysctl "net.ipv4.tcp_max_orphans" do
  value node["sysctl"]["max_orphans"]
end

if node["dna"]["instance_role"][/db|solo/]
  include_recipe "ey-sysctl::tune_large_db"
end
