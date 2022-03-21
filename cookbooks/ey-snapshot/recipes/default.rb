unless node["dna"]["instance_role"] == "app"
  cron "ey-snapshots" do
    minute   node["snapshot_minute"]
    hour     node["snapshot_hour"]
    day      "*"
    month    "*"
    weekday  "*"
    command  "ey-snapshots --snapshot >> /var/log/ey-snapshots.log"
    not_if { node["backup_window"].to_s == "0" }
  end
end