class Chef
  class Node
    def instances
      node["dna"]["engineyard"]["environment"]["instances"]
    end

    def private_ip_for(instance)
      require "resolv"
      Resolv.getaddress(instance["private_hostname"])
    rescue Resolv::ResolvError
      nil
    end

    def cluster
      instances.map { |i| private_ip_for(i) }.compact
    end

    def app_master
      instances.select { |i| ["solo", "app_master"].include?(i["role"]) }.map { |i| private_ip_for(i) }.compact
    end

    def app_slaves
      instances.select { |i| ["app"].include?(i["role"]) }.map { |i| private_ip_for(i) }.compact
    end

    def app_servers
      app_master + app_slaves
    end

    def util_servers
      instances.select { |i| ["util"].include?(i["role"]) }.map { |i| private_ip_for(i) }.compact
    end

    def db_servers
      db_master + db_slaves
    end

    def db_master
      instances.select { |i| ["db_master"].include?(i["role"]) }.map { |i| private_ip_for(i) }.compact
    end

    def db_slaves
      instances.select { |i| ["db_slave"].include?(i["role"]) }.map { |i| private_ip_for(i) }.compact
    end

    def stack
      node.engineyard.environment["stack_name"]
    end
  end
end