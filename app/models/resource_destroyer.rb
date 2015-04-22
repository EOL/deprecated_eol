class ResourceDestroyer

  # NOTE: Perhaps not ideal, but we want the ruby worker to pick it up:
  @queue = 'data'

  # TODO: notifications. The user who submitted the request should get a comment
  # on their timeline when this is done, including any error messages.
  def self.perform(args)
    Rails.logger.error "ResourceDestroyer: #{args.values.join(', ')}"
    Resource.with_master do
      if Resource.exists?(args["id"])
        begin
          Resource.find(args["id"]).destroy
        rescue => e
          Rails.logger.error "ResourceDestroyer (#{args["id"]}) FAILED: "\
            " #{e.message}"
        end
      else
        Rails.logger.error "ResourceDestroyer: Resource #{args["id"]} doesn't exist, skippped."
      end
    end
    Rails.logger.error "ResourceDestroyer (#{args["id"]}) Done."
  end

  def self.enqueue(id)
    Resque.enqueue(ResourceDestroyer, id: id)
  end

end
