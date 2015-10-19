class HarvestEvent
  class Collection
    def sync(event)
      creator = new(event)
      creator.create
    end

    def initialize(event)
      @event = event
    end

    def sync
      collection.name = name
      collection.logo_cache_url = logo_url
      collection.description = description
      collection.save if collection.changed?
      add_user_to_collection
      # YOU WERE HERE

      # $this->sync_with_collection($collection);

      if @event.published?
        #     // make sure the collection can be searched for
        #     $indexer = new SiteSearchIndexer();
        #     $indexer->index_collection($collection->id);
        resource.preview_collection.users = []
        resource.preview_collection.destroy
      end
    end

    private

    def collection
      @collection ||= create_collection
    end

    def content_partner
      resource.content_partner
    end

    def create_collection
      if @event.published?
        if resource.collection.nil?
          resource.collection = create_collection_object
          resource.save
        end
        resource.collection
      else
        if resource.preview_collection.nil?
          resource.preview_collection = create_collection_object
          resource.save
        end
        resource.preview_collection
      end
    end

    def create_collection_object
      Collection.create(
        description: description,
        logo_cache_url: logo_url,
        name: name,
        published: true
      )
    end

    def description
      description = content_partner.description.strip
      description += "." unless description[-1] == "."
      description += " Last indexed #{Date.today.strftime('%b %d, %Y')}"
      description
    end

    def add_user_to_collection
      collection.users << @user unless collection.users.include?(user)
    end

    def logo_url
      content_partner.logo_cache_url ||
        user.logo_cache_url
    end

    def name
      resource.title
    end

    def resource
      @event.resource
    end

    def user
      content_partner.user
    end
  end
end
