size = node["dna"]["environment"]["instance_size"] || ec2_instance_size
default["collectd"] = default_collectd(size)
default["swap_warn_threshold"] = "0.50"
default["swap_crit_threshold"] = "0.70"
