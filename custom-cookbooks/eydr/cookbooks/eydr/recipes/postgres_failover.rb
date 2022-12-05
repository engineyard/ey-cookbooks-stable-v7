#
# Cookbook:: dr_failover
# Recipe:: postgresql_failover
#

bash "promote-slave-to-master" do
  code "touch /tmp/postgresql.trigger"
end

# Restart postgres? Remove trigger file after restart?
