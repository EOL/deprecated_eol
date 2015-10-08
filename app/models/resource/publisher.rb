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
        raise "No hierarchy!" unless @resource.
        @harvest_event.show_preview_objects_TODO # harvest_event->make_objects_visible
        @harvest_event.preserve_curations # Also TODO, but see class
        @resource.unpublish_data_objects_TODO
        @harvest_event.publish_data_objects_TODO # $harvest_event->publish_objects();
        @harvest_event.update_attributes(published_at: Time.now)
      end
      ActiveRecord::Base.connection.transaction do
        @resource.unpublish_hierarchy_entries_TODO
      end
      ActiveRecord::Base.connection.transaction do
        @harvest_event.publish_hierarchy_entries_TODO
      end
      TaxonConcept.post_harvest_cleanup(@resource)

      # YOU WERE HERE - TODO
      # // Rebuild the Solr index for this hierarchy
      # $indexer = new HierarchyEntryIndexer();
      # $indexer->index($this->hierarchy_id);
      #
      # // Compare this hierarchy to all others and store the
      # // results in the hierarchy_entry_relationships table
      # $harvest_event->compare_new_hierarchy_entries();
      # $harvest_event->create_taxon_relations_graph();
      #
      # $this->update_names();
      # $this->mysqli->commit();
      #
      # $harvest_event->resource->refresh();
      # $harvest_event->create_collection();
      # $harvest_event->index_for_search();
      #
      # $this->mysqli->update("UPDATE resources SET resource_status_id=". ResourceStatus::published()->id ." WHERE id=$this->id");
      # $this->mysqli->end_transaction();
      @resource.save_resource_contributions
    end
  end
end
