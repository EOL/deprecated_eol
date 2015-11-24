class Resource
  class Harvester
    def self.harvest(resource)
      harvester = self.new(resource)
      harvester.harvest
    end

    def initialize(resource)
      @resource = resource
    end

    def harvest
      EOL.log_call
      # TODO: YOU WERE HERE: you'll have to call PHP, now. :(
    end
  end
end
