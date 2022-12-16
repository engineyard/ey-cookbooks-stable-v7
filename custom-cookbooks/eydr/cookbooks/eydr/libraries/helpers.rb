module PostgreSQL
  module Helper
    def pg_eydr_replicating_from_master
      `psql -U postgres -c "select conninfo from pg_stat_wal_receiver;" | grep host=127.0.0.1 | awk '{print $5}'`.strip == "host=127.0.0.1"
    end

    def pg_eydr_streaming
      `psql -U postgres -c "select status from pg_stat_wal_receiver;" | grep streaming | awk '{print $NF}'`.strip == "streaming"
    end

    def pg_in_recovery
      `psql -U postgres -c "select pg_is_in_recovery();" | grep t | awk '{print $NF}'`.strip == "t"
    end
  end
end

Chef::DSL::Recipe.send(:include, PostgreSQL::Helper)
Chef::Resource.send(:include, PostgreSQL::Helper)
