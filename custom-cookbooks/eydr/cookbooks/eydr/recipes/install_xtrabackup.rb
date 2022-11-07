#
# Cookbook:: dr_replication
# Recipe:: install_xtrabackup
#

# Download xtrabackup from URL specificed in attributes
bash 'download-xtrabackup' do
  user node['owner_name']
  code "cd /home/#{node['owner_name']}/ && wget #{node['dr_replication']['xtrabackup_download_url']}"
  not_if { ::File.exist? "/home/#{node['owner_name']}/#{node['dr_replication']['xtrabackup_download_url'].split('/').last}" }
end

# Untar xtrabackup
bash 'untar-xtrabackup' do
  user node['owner_name']
  code "cd /home/#{node['owner_name']}/ && tar -xvf #{node['dr_replication']['xtrabackup_download_url'].split('/').last}"
end

# Copy xtrabackup into /usr/bin so that it's in the PATH
bash 'copy-xtrabackup' do
  user 'root'
  code "yes | cp -ruf /home/#{node['owner_name']}/#{node['dr_replication']['xtrabackup_download_url'].split('/').last.split('-')[0..2].join('-')}*/bin/* /usr/bin/"
end

# Ensure proper ownership
bash 'chown-xtrabackup' do
  user 'root'
  cwd '/usr/bin/'
  code "chown #{node['owner_name']}:#{node['owner_name']} innobackupex xbcrypt xbstream xtrabackup*"
end

# Install libaio (required for xtrabackup)
package 'dev-libs/libaio' do
  action :install
end

# Download qpress from the URL specified in attributes (used for compression)
bash 'download-qpress' do
  user node['owner_name']
  cwd "/home/#{node['owner_name']}/"
  code "wget #{node['dr_replication']['qpress_download_url']}"
  not_if { ::File.exist? "/home/#{node['owner_name']}/#{node['dr_replication']['qpress_download_url'].split('/').last}" }
end

# Untar qpress
bash 'copy-qpress' do
  user node['owner_name']
  cwd "/home/#{node['owner_name']}/"
  code "tar xvf #{node['dr_replication']['qpress_download_url'].split('/').last}"
end

# Copy apress into /usr/bin so that it's in the PATH
bash 'copy-qpress' do
  user 'root'
  code "yes | cp -ruf /home/#{node['owner_name']}/qpress /usr/bin/"
end
