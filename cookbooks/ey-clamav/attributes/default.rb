require "json"

default["clamav"]["version"] = "0.103.6+dfsg-0ubuntu0.20.04.1"

def get_path_array(scanpath_var)
  if scanpath_var.is_a? String
    @scanpath_var = JSON.parse scanpath_var
    @paths = []
    @scanpath_var.each do |path|
      @paths.push(path)
    end
    return @paths
  else
    return []
  end
end

default["clamav"]["scanpath_app"] = get_path_array(fetch_env_var(node, "EY_CLAMAV_APP_PATHS", []))
default["clamav"]["scanpath_db"] = get_path_array(fetch_env_var(node, "EY_CLAMAV_DB_PATHS", []))
default["clamav"]["scanpath_util"] = get_path_array(fetch_env_var(node, "EY_CLAMAV_UTIL_PATHS", []))
default["clamav"]["scanpath_solo"] = get_path_array(fetch_env_var(node, "EY_CLAMAV_SOLO_PATHS", []))

default["clamav"]["autoremove_infected"] = fetch_env_var(node, "EY_CLAMAV_AUTOREMOVE_INFECTED", false)
default["clamav"]["quarantine_directory"] = "/mnt/quarantine"