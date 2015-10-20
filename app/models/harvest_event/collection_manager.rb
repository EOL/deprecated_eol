class HarvestEvent
  class CollectionManager
    def sync(event)
      creator = new(event)
      creator.create
    end

    def initialize(event)
      @event = event
    end

    def sync
      update_attributes
      add_user_to_collection
      remove_collection_items_not_in_harvest

      # YOU WERE HERE

      # TODO: rename, it's a beast. Move it, too.
      starting_max_collection_item_id = CollectionItem.
        where(collection_id: collection.id).maximum(:id) || 0
      # $this->add_objects_to_collection($collection);
      # $this->add_taxa_to_collection($collection);
      #
      # $collection_items_to_index = array();
      # $query = "SELECT id FROM collection_items WHERE collection_id=$collection->id AND id > $starting_max_collection_item_id";
      # foreach($GLOBALS['db_connection']->iterate_file($query) as $row) $collection_items_to_index[] = $row[0];
      # if($collection_items_to_index)
      # {
      #     $indexer = new CollectionItemIndexer();
      #     $indexer->index_collection_items($collection_items_to_index);
      # }
      # $collection->set_item_count();

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

    def remove_collection_items_not_in_harvest
      CollectionItem.data_objects.
        select("collection_items.id").
        joins("LEFT JOIN data_objects_harvest_events dohe ON "\
          "(collection_items.collected_item_id = dohe.data_object_id "\
          "AND dohe.harvest_event_id = #{@event.id})").
        where(collection_id: collection.id).
        where("data_object_id IS NULL").
        delete_all
      CollectionItem.taxa.
        select("collection_items.id").
        joins("LEFT JOIN (harvest_events_hierarchy_entries hehe JOIN "\
          "hierarchy_entries he ON (hehe.hierarchy_entry_id=he.id AND "\
          "hehe.harvest_event_id = #{@event.id})) ON "\
          "(collection_items.collected_item_id = he.taxon_concept_id)").
        where(collection_id: collection.id).
        where("hehe.hierarchy_entry_id IS NULL").
        delete_all
    end

    def resource
      @event.resource
    end

    def update_attributes
      collection.name = name
      collection.logo_cache_url = logo_url
      collection.description = description
      collection.save if collection.changed?
    end

    def user
      content_partner.user
    end
  end
end
