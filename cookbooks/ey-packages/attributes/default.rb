default["packages"].tap do |packages|
  packages["install"] = fetch_env_var(node, "EY_PACKAGES", "{}").split(",")
  packages["apt_sources"] = fetch_env_var(node, "EY_SOURCES_PACKAGES", "{}").split(",")
end