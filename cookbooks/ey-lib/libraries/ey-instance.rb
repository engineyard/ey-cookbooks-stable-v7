class Chef
  module EY
    class Instance
      def initialize(hash, node)
        @hash = hash
        @node = node
      end

      def id
        @hash["id"]
      end

      def component?(name)
        @hash["components"].any? { |c| c["key"] == name.to_s }
      end

      def component(name)
        @hash["components"].detect { |c| c["key"] == name.to_s }
      end

      def arch_type
        case node["kernel"]["machine"]
        when /(x86.*)/
          "amd64"
        when /(aarch.*)/
          "arm64"
        end
      end

      def roles
        case role
        when "solo"
          ["db_master", "app"]
        when "app", "app_master"
          ["app"]
        when "db_slave"
          ["db_replica"]
        else
          [role]
        end
      end

      def has_role?(*desired_roles)
        (roles.map(&:to_sym) & desired_roles.map(&:to_sym)).any?
      end

      def app_master?
        role == "app_master"
      end

      def app_server?
        ["app_master", "solo", "app"].include?(role)
      end

      def database_server?
        ["db_master", "db_slave", "db_replica", "solo"].include?(role)
      end

      def primary_database_server?
        ["db_master", "solo"].include?(role)
      end

      def solo?
        role == "solo"
      end

      def util?
        role == "util"
      end

      # Support a more natural way of accessing hash members and components
      def respond_to?(method)
        # @hash.key? method is broken so check keys list
        ([method, method.to_s] - @hash.keys).length < 2 || component?(method.to_s) || super
      end

      def method_missing(method, *args)
        respond_to?(method) ? (@hash[method] || @hash[method.to_s] || component?(method.to_s) || super) : super
      end
    end
  end
end