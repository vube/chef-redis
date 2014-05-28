#
# Cookbook Name:: redis
# Recipe:: default
#
# Copyright 2014, Vubeology LLC
#

include_recipe "apt"
include_recipe "build-essential"

if node['redis']['package_url'].to_s.empty?
  raise "You must configure node[:redis][:package_url]"
end

bash "download redis package" do
  code <<-EOH
  if [ ! -d "#{node['redis']['build_dir']}" ]; then
    cd "`dirname #{node['redis']['build_dir']}`" || exit 1
    mkdir "`basename #{node['redis']['build_dir']}`" || exit 2
  fi
  cd "#{node['redis']['build_dir']}" || exit 6
  wget "#{node['redis']['package_url']}" --output-document=redis.deb || exit 9
  EOH
  not_if { ::File.exist?("#{node['redis']['executable']}") || ::File.exist?("#{node['redis']['build_dir']}/redis.deb") }
end

bash "install redis" do
  cwd "#{node['redis']['build_dir']}"
  code <<-EOH
  sudo dpkg -i redis.deb > redis.install_log 2>&1
  EOH
  not_if { ::File.exist?("#{node['redis']['executable']}") }
end

bash "create redis group" do
  code <<-EOH
  sudo addgroup --system "#{node['redis']['user_group']}"
  EOH
  # But don't do this if the user group already exists
  not_if "grep '#{node['redis']['user_group']}' /etc/group"
end

# Create a redis user if necessary
bash "create redis user" do
  code <<-EOH
  sudo adduser --system --no-create-home --ingroup "#{node['redis']['user_group']}" "#{node['redis']['username']}"
  EOH
  # But don't do this if the username already exists
  not_if "id '#{node['redis']['username']}'"
end

# Create directories and give redis user write permissions in them
%w[/etc/redis /var/log/redis].each do |path|
  directory path do
    owner node['redis']['username']
    group node['redis']['user_group']
    mode 0775
    action :create
  end
end

# Initialize redis data bag
redis_data = []
begin
  redis_data = data_bag(node["redis"]["data_bag_name"])
rescue
  Chef::Log.warn "Failed to load #{node["redis"]["data_bag_name"]} data_bag"
end

# Initialize any server instances on the VM based on the data_bag config

begin
  instances = data_bag_item(node["redis"]["data_bag_name"], "instances")
rescue
  Chef::Log.info "No redis instances specified in #{node["redis"]["data_bag_name"]} data_bag"
  instances = { "instances" => [] }
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
