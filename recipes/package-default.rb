#
# Cookbook Name:: redis
# Recipe:: package-custom
#
# Copyright 2014, Vubeology LLC
#

package "redis-server"

# We don't want the default server startup script that package installs,
# so stop it running and disable it on future startup
service "redis-server" do
  action [:stop, :disable]
end

# We don't want the default redis.conf that package installs, so
# delete it if it exists
file "/etc/redis/redis.conf" do
  action :delete
end
