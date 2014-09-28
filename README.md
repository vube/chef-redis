redis Chef Cookbook
===================

This cookbook installs Redis.

This requires that you have a Debian package that actually installs Redis, and this
cookbook primarily concerns itself with configuring redis on the system after it has
been compiled/installed by your package maintainer.

## Installation

Add a submodule dependency to your project, I'm assuming here that chef/cookbooks/ is the sub-directory
where you want your cookbook dependencies installed.  Whatever path you choose to check it out to, make
sure that is in your cookbook search path.

```bash
$ git submodule add https://github.com/vube/chef-redis chef/cookbooks/chef-redis
```

### In your metadata.rb
```ruby
depends "chef-redis"
```

### In your recipe.rb
```ruby
include_recipe "chef-redis"
```

## Configuration

To configure this you must include a redis/instances.json data_bag in your main chef recipe.

You must also set the download URL of the redis.deb Debian package that will actually install
redis the way you want.  In the future I'd like to update this so that it offers source compilations,
etc but currently you need to do that part on your own, this only handles configuration and initialization
of redis.

### attributes/default.rb

```ruby
overrides['redis']['package_url'] = 'http://your.download-server.com/redis.deb'
```

### Examples

#### Single redis instance

```json
{
	"id": "instances",
	"instances": [{
		"id": "my_instance_1",
		"port": 6375,
		"max_memory": "64m"
	}]
}
```

#### Multiple redis instances on different ports

```json
{
	"id": "instances",
	"instances": [{
		"id": "my_instance_1",
		"port": 5375,
		"max_memory": "512m"
	},{
		"id": "my_instance_2",
		"port": 5376,
		"max_memory": "8g"
	}]
}
```
