provides :logrotate
unified_mode true

property :frequency, String, default: "daily"
property :rotate_count, Integer, default: 30
property :rotate_if_empty, [true, false], default: false
property :missing_ok, [true, false], default: true
property :compress, [true, false], default: true
property :enable, [true, false], default: true
property :date_ext, [true, false], default: true
property :extension, String, default: "gz"
property :files, String
property :restart_command, String
property :copy_then_truncate, [true, false], default: false
property :delay_compress, [true, false], default: false

default_action :logrotate_action

action :logrotate_action do
  template "/etc/logrotate.d/#{new_resource.name}" do
    action new_resource.enable ? :create : :delete
    cookbook "ey-logrotate"
    source "logrotate.conf.erb"
    variables(
      frequency: new_resource.frequency,
      rotate_count: new_resource.rotate_count,
      rotate_if_empty: new_resource.rotate_if_empty,
      missing_ok: new_resource.missing_ok,
      compress: new_resource.compress,
      date_ext: new_resource.date_ext,
      extension: new_resource.extension,
      files: new_resource.files,
      copy_then_truncate: new_resource.copy_then_truncate,
      restart_command: new_resource.restart_command,
      delay_compress: new_resource.delay_compress
    )
    backup false
    owner "root"
    group "root"
    mode "0644"
  end
end
