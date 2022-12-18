clamav = node["clamav"]
autoremove_infected = clamav["autoremove_infected"]
$quarantine_directory = clamav["quarantine_directory"]

directory $quarantine_directory do
  action "create"
end

cron "update clamav knowledgebase" do
  time :daily
  command "systemctl stop clamav-daemon && freshclam && systemctl start clamav-daemon"
  user "root"
end

def clamav_scan_cron(scanpath, autorm_infected = true)
  scanpath.each { |path|
    command = "clamscan --recursive " + path
    cron_name = node["dna"]["instance_role"] + " clamav cron for " + path
    if autorm_infected
      command << " --remove"
    else
      command << " --move #{$quarantine_directory}"
    end
    cron cron_name do
      minute 0
      hour 5
      command command + " >> /var/log/clamav/clamav-$(date +'%Y%m%d')"
      user "root"
    end
  }
end

unless clamav["scanpath_" + node["dna"]["instance_role"].split("_")[0]].empty?
  clamav_scan_cron(clamav["scanpath_" + node["dna"]["instance_role"].split("_")[0]], autoremove_infected)
end