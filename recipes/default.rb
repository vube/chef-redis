#
# Cookbook Name:: redis
# Recipe:: default
#
# Copyright 2014, Vubeology LLC
#

include_recipe "apt"

if node['redis']['package_url'].to_s.empty?
  raise "You must configure node[:redis][:package_url]"
end

EXE_FILE = "#{node['redis']['install_prefix']}/#{node['redis']['executable']}"

bash "download redis package" do
  code <<-EOH
  if [ ! -d "#{node['redis']['build_dir']}" ]; then
    cd "`dirname #{node['redis']['build_dir']}`" || exit 1
    mkdir "`basename #{node['redis']['build_dir']}`" || exit 2
  fi
  cd "#{node['redis']['build_dir']}" || exit 6
  # If the package_url is a Google Cloud Storage URL, then use gsutil to copy it
  if echo "#{node['redis']['package_url']}" | grep "^gs://" > /dev/null; then
    gsutil cp "#{node['redis']['package_url']}" redis.deb || exit 8
  # Else anything else is a URL that wget can fetch
  else
    wget "#{node['redis']['package_url']}" --output-document=redis.deb || exit 9
  fi
  EOH
  not_if { ::File.exist?(EXE_FILE) || ::File.exist?("#{node['redis']['build_dir']}/redis.deb") }
end

bash "install redis" do
  cwd "#{node['redis']['build_dir']}"
  code <<-EOH
  sudo dpkg -i redis.deb > redis.install_log 2>&1
  EOH
  not_if { ::File.exist?(EXE_FILE) }
end

bash "create redis group" do
  code <<-EOH
  sudo addgroup --system "#{node['redis']['user_group']}"
  EOH
  # But don't do this if the user group already exists
  not_if "awk -F: '$1 == \"#{node['redis']['user_group']}\" {print $3}' /etc/group"
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


# Initialize any instances
include_recipe "chef-redis::instance"
