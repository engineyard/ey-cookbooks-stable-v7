thp_filename = "/sys/kernel/mm/transparent_hugepage/enabled"
if ::File.exist?(thp_filename)
  execute "disable transparent huge pages when present" do
    command "echo never > #{thp_filename}"
  end

  sysctl "vm.dirty_ratio" do
    value "80"
  end

  sysctl "vm.dirty_background_ratio" do
    value "5"
  end

  sysctl "vm.dirty_expire_centisecs" do
    value "12000"
  end
end