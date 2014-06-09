#
# Cookbook Name:: redis
# Recipe:: instance
#
# Copyright 2014, Vubeology LLC
#

# Initialize any server instances on the VM based on the data_bag config

instances = { "instances" => [] }
begin
  instances = data_bag_item(node["redis"]["data_bag_name"], "instances")
rescue
  Chef::Log.info "No redis instances specified in #{node["redis"]["data_bag_name"]} data_bag"
end

instances["instances"].each do |instance|

  # Compute the data directory for this instance
  # By default its the {base_data_dir}/{port}
  # But instances can override the data_dir if they want
  data_dir = instance['data_dir'].to_s.empty? ? node['redis']['base_data_dir']+"/"+instance["port"].to_s : instance['data_dir']

  # Create the data_dir for this instance if needed
  directory data_dir do
    owner node['redis']['username']
    group node['redis']['user_group']
    mode 0775
    recursive true
    action :create
  end

  # Install the instance init.d startup script
  # Install the instance config
  template "/etc/redis/redis_#{instance['port']}.conf" do
    source "redis.conf.erb"
    action :create_if_missing
    owner node['redis']['username']
    group node['redis']['user_group']
    mode 0644
    variables :id => instance['id'],
              :port => instance['port'],
              :max_memory => instance['max_memory'],
              :data_dir => data_dir,
              :install_prefix => instance['install_prefix'].to_s.empty? ? node['redis']['install_prefix'] : instance['install_prefix'],
              :username => node['redis']['username'],
              :usergroup => node['redis']['user_group']
  end

  # Install the instance init.d startup script
  # Install the instance config
  template "/etc/init.d/redis_#{instance['port']}" do
    source "redis.sh.erb"
    action :create_if_missing
    owner "root"
    group "root"
    mode 0755
    variables :id => instance['id'],
              :port => instance['port'],
              :install_prefix => instance['install_prefix'].to_s.empty? ? node['redis']['install_prefix'] : instance['install_prefix'],
              :username => node['redis']['username'],
              :usergroup => node['redis']['user_group']
  end

  # Make redis start when the VM boots
  execute "update-rc.d redis_#{instance['port']}" do
    command "sudo update-rc.d redis_#{instance['port']} defaults > /tmp/redis_#{instance['port']}.update-rc.d_log 2>&1"
  end

  # Start redis now if it is not already running
  execute "start redis_#{instance['port']}" do
    command "sudo /etc/init.d/redis_#{instance['port']} start > /tmp/redis_#{instance['port']}.startup_log 2>&1"
    # But don't start it if it's already running
    not_if "ps auxgww | grep -v grep | grep redis-server | grep #{instance['port']}"
  end

end
