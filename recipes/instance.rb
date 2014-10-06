#
# Cookbook Name:: redis
# Recipe:: instance
#
# Copyright 2014, Vubeology LLC
#

# Initialize any server instances on the VM

node["redis"]["instances"].each do |instance|

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
    action :create
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
    notifies :restart, "service[redis_#{instance['port']}]"
  end

  # Install the instance init.d startup script
  # Install the instance config
  template "/etc/init.d/redis_#{instance['port']}" do
    source "redis.sh.erb"
    action :create
    owner "root"
    group "root"
    mode 0755
    variables :id => instance['id'],
              :port => instance['port'],
              :install_prefix => instance['install_prefix'].to_s.empty? ? node['redis']['install_prefix'] : instance['install_prefix'],
              :username => node['redis']['username'],
              :usergroup => node['redis']['user_group']
    notifies :restart, "service[redis_#{instance['port']}]"
  end

  # Start the service and enable it on machine boot
  service "redis_#{instance['port']}" do
    supports :restart => true
    action [:start, :enable]
  end

end
