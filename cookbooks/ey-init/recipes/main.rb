require "pp"

include_recipe "ey-base::resin_gems"
include_recipe "ey-core"
include_recpe "ey-custom::before-main"
include_recipe "ey-base::bootstrap"
node.engineyard.instance.roles.each { |role| include_recipe "ey-#{role}::prep" }
# node.engineyard.instance.roles.each { |role| include_recipe "ey-#{role}::build" }
include_recipe "ey-base::post_bootstrap"
include_recpe "ey-custom::after-main"
include_recipe "ey-base::custom"