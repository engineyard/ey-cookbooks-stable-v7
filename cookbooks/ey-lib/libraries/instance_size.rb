class Chef
  class Node
    def ec2_instance_size
      require "open-uri"
      @ec2_instance_size ||= URI.open("http://169.254.169.254/latest/meta-data/instance-type").read
    end
  end
end