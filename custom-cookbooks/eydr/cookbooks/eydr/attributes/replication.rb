default["dr_replication"] = {
  production: {
    master: {
      public_hostname: "",
    },
    # MySQL Only
    initiate: {
      public_hostname: "",
    },
    slave: {
      public_hostname: "",
    },
  },
  # The following 2 URLs are required for MySQL replication
  xtrabackup_download_url: "https://downloads.percona.com/downloads/Percona-XtraBackup-LATEST/Percona-XtraBackup-8.0.29-22/binary/debian/focal/x86_64/Percona-XtraBackup-8.0.29-22-rc31e7ddcce3-focal-x86_64-bundle.tar",
  qpress_download_url: "http://www.quicklz.com/qpress-11-linux-x64.tar",
}

# Set to true to establish replication during Chef run
default["establish_replication"] = false

# Set to true to failover to D/R environment during Chef run
default["failover"] = false
