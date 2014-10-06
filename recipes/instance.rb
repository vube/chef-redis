#
# Cookbook Name:: redis
# Recipe:: instance
#
# Copyright 2014, Vubeology LLC
#

# Initialize any server instances on the VM

node['redis']['instances'].each do |id, instance|

  # Compute the data directory for this instance
  # By default its the {base_data_dir}/{port}
  # But instances can override the data_dir if they want
  data_dir = (instance['data_dir'].nil? || instance['data_dir'].to_s.empty?) ? "#{node['redis']['base_data_dir']}/#{instance['port']}" : instance['data_dir']

  # Default service name is like "redis_123" where 123 is the port number
  # However you can override this if you want to be "redis_foo" or "redis" by
  # setting instance['service_id'] = '_foo' or '' respectively
  service_id = instance['service_id'].nil? ? "_#{instance['port']}" : instance['service_id']

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
  template "/etc/redis/redis#{service_id}.conf" do
    source "redis.conf.erb"
    action :create
    owner node['redis']['username']
    group node['redis']['user_group']
    mode 0644
    variables :id => id,
              :service_id => service_id,
              :db_filename => instance['db_filename'].nil? ? id : instance['db_filename'],
              :port => instance['port'],
              :max_memory => instance['max_memory'],
              :data_dir => data_dir,
              :log_level => instance['log_level'].nil? ? 'notice' : instance['log_level'],
              :install_prefix => instance['install_prefix'].to_s.empty? ? node['redis']['install_prefix'] : instance['install_prefix'],
              :username => node['redis']['username'],
              :usergroup => node['redis']['user_group']
    notifies :restart, "service[redis#{service_id}]"
  end

  # Install the instance init.d startup script
  # Install the instance config
  template "/etc/init.d/redis#{service_id}" do
    source "redis.sh.erb"
    action :create
    owner "root"
    group "root"
    mode 0755
    variables :id => id,
              :service_id => service_id,
              :port => instance['port'],
              :install_prefix => instance['install_prefix'].to_s.empty? ? node['redis']['install_prefix'] : instance['install_prefix'],
              :username => node['redis']['username'],
              :usergroup => node['redis']['user_group']
    notifies :restart, "service[redis#{service_id}]"
  end

  # Start the service and enable it on machine boot
  service "redis#{service_id}" do
    supports :restart => true
    action [:start, :enable]
  end

end
