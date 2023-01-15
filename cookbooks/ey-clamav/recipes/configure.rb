clamav = node["clamav"]
autoremove_infected = clamav["autoremove_infected"]
clamav_run_hour = clamav["runhour"]
clamav_run_minute = clamav["runminute"]
$quarantine_directory = clamav["quarantine_directory"]

directory $quarantine_directory do
  action "create"
end

cron "update clamav knowledgebase" do
  time :daily
  command "systemctl stop clamav-daemon && freshclam && systemctl start clamav-daemon"
  user "root"
end

def clamav_scan_cron(scanpath, autorm_infected = true, runhour = 5, runminute = 0)
  runhour_count = 0
  run_hour = runhour
  run_minute = runminute
  scanpath.each { |path|
    command = "clamscan --recursive " + path
    cron_name = node["dna"]["instance_role"] + " clamav cron for " + path
    if autorm_infected
      command << " --remove"
    else
      command << " --move #{$quarantine_directory}"
    end
    cron cron_name do
      minute runminute
      hour runhour
      command command + " >> /var/log/clamav/clamav"
      user "root"
    end

    runhour_count += 1
    if runhour_count >= 3
      run_hour += 1
    end

    run_minute += 20
    if run_minute >= 60
      run_minute = 0
    end
  }
end

unless clamav["scanpath_" + node["dna"]["instance_role"].split("_")[0]].empty?
  clamav_scan_cron(clamav["scanpath_" + node["dna"]["instance_role"].split("_")[0]], autoremove_infected)
end