require "pp"
#
# Cookbook:: ey-memcached
# Recipe:: default
#

include_recipe "ey-memcached::install"
include_recipe "ey-memcached::configure"
