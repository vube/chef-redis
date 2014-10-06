#
# Cookbook Name:: redis
# Recipe:: default
#
# Copyright 2014, Vubeology LLC
#

include_recipe "apt"

if node['redis']['package_url'].to_s.empty?
  package "redis-server"
else
  include_recipe 'chef-redis::package-custom'
end

# Initialize any instances
include_recipe "chef-redis::instance"
