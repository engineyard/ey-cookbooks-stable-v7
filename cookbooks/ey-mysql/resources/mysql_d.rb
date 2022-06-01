provides :handle_mysql_d
unified_mode true

property :name, String, default: "MySQL" # We set a default name as it is a requirement.

default_action :action_handle_mysql_d

action :action_handle_mysql_d do
  ruby_block "set up mysql.d custom config dir" do
    block do
      system("mkdir -p /db/mysql.d; chown mysql:mysql /db/mysql.d")
      system('[[ -n "$(ls /etc/mysql.d)" ]] && mv /etc/mysql.d/* /db/mysql.d/')
      system("mount --bind /db/mysql.d /etc/mysql.d")
      system("echo '/db/mysql.d /etc/mysql.d none bind' >> /etc/fstab")
    end

    not_if "grep -qs '/etc/mysql.d' /etc/fstab"
  end
end