if node["efs"]["exists"] == true
  include_recipe "ey-efs::configure"
end

if node["efs"]["exists"] == false && File.exist?("/opt/.efsid")
  include_recipe "ey-efs::remove"
end
