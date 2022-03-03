provides :ey_cloud_report
unified_mode true
property :message, String

default_action :send_message

action :send_message do
  Chef::Log.info new_resource.message
  execute "reporting for #{new_resource.name}" do
    command "ey-enzyme --report '#{new_resource.message}'"
    ignore_failure false
  end
end
