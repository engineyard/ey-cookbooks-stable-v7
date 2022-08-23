# Find all cron jobs specified in attributes/cron.rb where current node matches instance_name
#named_crons = node["custom_crons"].find_all { |c| c[:instance_name] == node["dna"]["name"] }

# Find all cron jobs for utility instances
#util_crons = node["custom_crons"].find_all { |c| c[:instance_name] == "util" }

# Find all cron jobs for app master only
#app_master_crons = node["custom_crons"].find_all { |c| c[:instance_name] == "app_master" }

# Find all cron jobs for solo only
#solo_crons = node["custom_crons"].find_all { |c| c[:instance_name] == "solo" }

# Find all cron jobs for application instances
#app_crons = node["custom_crons"].find_all { |c| c[:instance_name] == "app" }

# Find all cron jobs for ALL instances
#all_crons = node["custom_crons"].find_all { |c| c[:instance_name] == "all" }

# Find all cron jobs for Database instances
#db_crons = node["custom_crons"].find_all { |c| c[:instance_name] == "db" }

#crons = all_crons + named_crons

#if node["dna"]["instance_role"] == "util"
#  crons += util_crons
#end

#if node["dna"]["instance_role"] == "app_master"
#  crons += app_master_crons
#end

#if node["dna"]["instance_role"] == "solo"
#  crons += solo_crons
#end

#if node["dna"]["instance_role"] == "app" || node["dna"]["instance_role"] == "app_master"
#  crons += app_crons
#end

#if node["dna"]["instance_role"] == "db_master" || node["dna"]["instance_role"] == "db_slave"
#  crons += db_crons
#end

def delete_cron_jobs_not_in_custom(user, crons)
  # get the existing cron jobs created by this cron recipe
  existing_crons_command = Mixlib::ShellOut.new("grep -E -o '\# Chef Name: custom_cron_(.*)' /var/spool/cron/crontabs/#{user}")
  existing_crons_command.run_command
  existing_cron_names = existing_crons_command.stdout
  existing_crons = []

  # get the existing cron names without the prefix custom_cron_
  existing_cron_names.each_line do |line|
    existing_crons << line.chomp.gsub(/\# Chef Name: custom_cron_/, "")
  end
  Chef::Log.debug "current custom cron jobs #{existing_crons.inspect}"

  # get the cron jobs that don't exist on the custom-cron attributes
  deleted_crons = existing_crons - crons.map { |c| c[:name] }
  Chef::Log.debug "deleted custom cron jobs #{deleted_crons.inspect}"
  deleted_crons.each do |deleted_cron|
    cron "custom_cron_#{deleted_cron}" do
      user user
      action :delete
    end
  end
end

if crontab_instance?(node)
  if node["custom_crons"]; then
    # Find all cron jobs specified in attributes/cron.rb where current node matches instance_name
    named_crons = node["custom_crons"].find_all { |c| c[:instance_name] == node["dna"]["name"] }

    # Find all cron jobs for utility instances
    util_crons = node["custom_crons"].find_all { |c| c[:instance_name] == "util" }

    # Find all cron jobs for app master only
    app_master_crons = node["custom_crons"].find_all { |c| c[:instance_name] == "app_master" }

    # Find all cron jobs for solo only
    solo_crons = node["custom_crons"].find_all { |c| c[:instance_name] == "solo" }

    # Find all cron jobs for application instances
    app_crons = node["custom_crons"].find_all { |c| c[:instance_name] == "app" }

    # Find all cron jobs for ALL instances
    all_crons = node["custom_crons"].find_all { |c| c[:instance_name] == "all" }

    # Find all cron jobs for Database instances
    db_crons = node["custom_crons"].find_all { |c| c[:instance_name] == "db" }

    crons = all_crons + named_crons
    if node["dna"]["instance_role"] == "util"
      crons += util_crons
    end

    if node["dna"]["instance_role"] == "app_master"
      crons += app_master_crons
    end

    if node["dna"]["instance_role"] == "solo"
      crons += solo_crons
    end

    if node["dna"]["instance_role"] == "app" || node["dna"]["instance_role"] == "app_master"
      crons += app_crons
    end

    if node["dna"]["instance_role"] == "db_master" || node["dna"]["instance_role"] == "db_slave"
      crons += db_crons
    end
  else
    crons = []
  end
  delete_cron_jobs_not_in_custom(node["owner_name"], crons)
  delete_cron_jobs_not_in_custom("root", crons)
  crons.each do |c|
    custom_cron_name = "custom_cron_#{c['name']}"
    cron custom_cron_name do
      user node["owner_name"]
      action :create
      minute c[:time].split[0]
      hour c[:time].split[1]
      day c[:time].split[2]
      month c[:time].split[3]
      weekday c[:time].split[4]
      command c[:command]
    end
  end
end
