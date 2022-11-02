## ey-redis - Optional Cookbook for Engine Yard Cloud

## Redis

[Redis][1] Redis is an open source, advanced key-value store. It is often referred to as a data structure server since keys can contain [strings][6], [hashes][5], [lists][4], [sets][3] and [sorted sets][2]. Learn More at the [introduction][7].i

## Overview

This cookbook provides a method to host a dedicated redis instance. This recipe should *NOT* be used on your Database instance as it is not designed for that instance. Additionally, it will not change nor modify your database instance in anyway.

## Installation

### Environment Variables

When the environment variable `EY_REDIS_ENABLED` is set to `true`, this recipe will be enabled and setup Redis on a utility instance named `redis` by default.

| Environment Variable             | Default Value | Description                                          |
|----------------------------------|---------------|------------------------------------------------------|
| `EY_REDIS_ENABLED`               | `false`       | Enabled Redis Installation                           |
| `EY_REDIS_VERSION`               | N/A           | Allows setting a custom version.^                    |
| `EY_REDIS_FORCE_UPGRADE`         | `false`       | Allows chef run to check for upgrade every execution |
| `EY_REDIS_INSTANCE_NAME`         | `redis`       | Pattern to match for instance name.^^                |
| `EY_REDIS_INSTANCE_ROLE`         | `util`        | Pattern to match for instance role.^^                |

^ : To install a version of Redis other than the default on Ubuntu 20.04 (5.0.7)
    Available from [https://github.com/antirez/redis/releases](https://github.com/antirez/redis/releases) 

^^: These environment variables match instances by their role and name.
    If variables are not set, it will install redis on Utility instance named as `redis`.
    The values are regular expression.
    The two matches are combines via a logical `and`.
    Other values for `EY_REDIS_INSTANCE_ROLE` are `solo` and `app_master`.
   
   


## Custom Chef

Since this is an optional recipe, it can be installed by simply including it via a `depends` in your `ey-custom/metadata.rb` fild and an `include_recipe` in the appropriate hook file. For more details on optional recipes see the [redis example]. 

This recipe will only activate on instances with the exact name `redis`.

## Design

* 1+ utility instances
* over-commit is enabled by default to ensure the least amount of problems saving your database.
* 64-bit is required for storing over 2gigabytes worth of keys.
* /etc/hosts mapping for `redis-instance` so that a hard config can be used to connect

## Backups

This cookbook does not automate nor facilitate any backup method currently. By default, there is a snapshot enabled for your environment and that should provide a viable backup to recover from. If you have any backup concerns open a ticket with our [Support Team][8].

## Changing Defaults

A large portion of the defaults of this recipe have been moved to an attribute file; if you need to modify how often you save, you can review the attribute file and update as necessary.

## Choosing a different Redis version

This recipe installed Redis 5.0.7, which is the Ubuntu 20.04 default version.

To install a different version of Redis, set `:install_from_source` to true, override the `:version` attribute, and set the correct `:download_url`.
You can do this with a new file in `cookbooks/redis/attributes` such as `overrides.rb` which sets the attribute similar to:

```
  node["redis"]["install_from_source"] = true
  node["redis"]["version"] = "5.0-r6"
  node["redis"]["download_url"] = "https://github.com/antirez/redis/archive/#{node["redis"]["version"]}.tar.gz"
```

## Notes

1. Please be aware that these are default config files and will likely need to be updated.
2. This recipe will create a file named as `redis.yml` on `/data/{app_name}/shared/config/`.

## How to get Support

* https://web.libera.chat/?nick=EYGuest%7C?#redis
* This GitHub repository.

[1]: http://redis.io/
[2]: http://redis.io/topics/data-types#sorted-sets
[3]: http://redis.io/topics/data-types#sets
[4]: http://redis.io/topics/data-types#lists
[5]: http://redis.io/topics/data-types#hashes
[6]: http://redis.io/topics/data-types#strings
[7]: http://redis.io/topics/introduction
[8]: https://support.cloud.engineyard.com
