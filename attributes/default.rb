
# REQUIRED: package_url: where to download your redis.deb package from
default['redis']['package_url'] = ""

# build_dir: Which directory to download the Debian package to
default['redis']['build_dir'] = "/tmp/build-redis"

# install_prefix: Tells us the base directory where the package installs Redis
default['redis']['install_prefix'] = "/usr/local/redis"

# executable: The executable file that is the result of all this.
# This doesn't determine where to put it, it just lets us test if we
# have successfully completed the process. Relative to install_prefix
default['redis']['executable'] = "bin/redis-server"

# base_data_dir: Where to keep data files by default. We'll actually create
# a dir under this one based on the instance port; this is the base directory.
default['redis']['base_data_dir'] = "/data/redis"

# The username to run redis as
default['redis']['username'] = "redis"

# The user group to run redis as
default['redis']['user_group'] = "redis"

# Name of the data_bag holding configuration more info
default['redis']['data_bag_name'] = "redis"
