if fetch_env_var(node, "EY_REDIS_ENABLED") =~ /^TRUE$/i
  include_recipe "ey-redis"
end

if fetch_env_var(node, "EY_MEMCACHED_ENABLED") =~ /^TRUE$/i
  include_recipe "ey-memcached"
end

if fetch_env_var(node, "EY_SIDEKIQ_ENABLED") =~ /^TRUE$/i
  include_recipe "ey-sidekiq"
end

if fetch_env_var(node, "EY_LETSENCRYPT_ENABLED") =~ /^TRUE$/i
  include_recipe "ey-letsencrypt"
end

if fetch_env_var(node, "EY_FAIL2BAN_ENABLED") =~ /^TRUE$/i
  include_recipe "ey-fail2ban"

unless fetch_env_var(node, "EY_LOGENTRIES_API_KEY").nil?
  include_recipe "ey-logentries"
end