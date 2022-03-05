cron "ntp_check" do
  minute    "2"
  hour      "*/6"
  command   "/engineyard/bin/ey-ntp-check"
  action :create
end