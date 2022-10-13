#
# Cookbook Name:: ey-le
# Recipe:: default
#
include_recipe 'ey-le::install'
include_recipe 'ey-le::configure'
include_recipe 'ey-le::start'
