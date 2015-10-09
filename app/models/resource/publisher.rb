class Resource
  class Publisher
    attr_reader :resource, :harvest_event

    def self.publish(resource)
      publisher = self.new(resource)
      publisher.publish
    end

    def initialize(resource)
      @resource = Array(resource)
      @harvest_event = HarvestEvent.where(resource_id: @resource.id).last
    end

    # NOTE: yes, PHP used multiple transactions. I suppose it was to avoid
    # locking the DB for too long, but I wonder if it was wise? TODO: consider
    # whether we acutally _need_ transactions! ...We can assume the HEs that
    # we're working on are not being touched... the worst that might happen is
    # curation of something that gets missed here, but we might be able to
    # capture that in another way.
    def publish
      EOL.log_call
      ActiveRecord::Base.connection.transaction do
        raise "No harvest event!" unless @harvest_event
        raise "Harvest event not published!" unless @harvest_event.published?
        raise "Harvest event not complete!" unless @harvest_event.complete?
        raise "Publish flag not set!" unless @harvest_event.publish?
        raise "No hierarchy!" unless @resource.hierarchy
        @harvest_event.show_preview_objects
        @harvest_event.preserve_invisible
        # TODO: I'm not sure we preserve _curations_. :\ We _only_ preserve
        # invisibilities... but we don't ever touch
        # curated_data_objects_hierarchy_entries in this process, so perhaps we
        # don't have to?
        @resource.unpublish_data_objects
        @harvest_event.publish_data_objects
      end
      ActiveRecord::Base.connection.transaction do
        @resource.unpublish_hierarchy
        @harvest_event.publish_hierarchy_entries
      end
      TaxonConcept.post_harvest_cleanup(@resource)
      SolrCore::HierarchyEntries.reindex_hierarchy(@resource.hierarchy)
      @harvest_event.compare_hierarchy_entry_relationships_TODO
      # That will be : $harvest_event->compare_new_hierarchy_entries(); and
      # $harvest_event->create_taxon_relations_graph();
      ActiveRecord::Base.connection.transaction do
        @resuorce.update_names_TODO # $this->update_names();
      end
      ActiveRecord::Base.connection.transaction do
        @harvest_event.create_collection_TODO # $harvest_event->create_collection();
      end
      @harvest_event.index_for_search_TODO # $harvest_event->index_for_search();
      @resource.update_attributes(resource_status_id:
        ResourceStatus.published.id)
      @resource.save_resource_contributions
    end
  end
end
