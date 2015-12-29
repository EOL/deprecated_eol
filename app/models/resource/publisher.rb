class Resource
  class Publisher
    attr_reader :resource, :harvest_event

    def self.publish(resource)
      publisher = self.new(resource)
      publisher.publish
    end

    def self.preview(resource)
      publisher = self.new(resource)
      publisher.preview
    end

    def initialize(resource)
      @resource = resource
      @harvest_event = resource.harvest_events.last
    end

    # A "light" version of publishing for resources that we keep in
    # "preview mode"
    def preview
      SolrCore::HierarchyEntries.reindex_hierarchy(@resource.hierarchy)
      @harvest_event.merge_matching_concepts
      @harvest_event.sync_collection
      denormalize
      true
    end

    def denormalize
      @resource.hierarchy.insert_data_objects_taxon_concepts
      # TODO: this next command isn't technically enough. (it will work, but it
      # will leave zombie entries). We need to add a step that says "delete all
      # entries in dotoc where ids in (list of ids that were in previous event
      # but not this one)"
      @harvest_event.insert_dotocs
    end

    # NOTE: yes, PHP used multiple transactions. I suppose it was to avoid
    # locking the DB for too long, but I wonder if it was wise? TODO: consider
    # whether we acutally _need_ transactions! ...We can assume the HEs that
    # we're working on are not being touched... the worst that might happen is
    # curation of something that gets missed here, but we might be able to
    # capture that in another way. NOTE: This _requires_ that the flattened
    # hierarchy have been rebuilt when this is called.
    def publish
      EOL.log_call
      EOL.log("Publishing #{resource.title}")
      raise "No harvest event!" unless @harvest_event
      raise "Harvest event already published!" if @harvest_event.published?
      raise "Harvest event not complete!" unless @harvest_event.complete?
      raise "Publish flag not set!" unless @harvest_event.publish?
      raise "No hierarchy!" unless @resource.hierarchy
      ActiveRecord::Base.connection.transaction do
        @harvest_event.show_preview_objects
        @harvest_event.preserve_invisible
      end
      ActiveRecord::Base.connection.transaction do
        @resource.unpublish_data_objects
        @harvest_event.publish_data_objects
      end
      ActiveRecord::Base.connection.transaction do
        old_entry_ids = Set.new(@resource.unpublish_hierarchy)
        # TODO: that's a bad name.
        @harvest_event.finish_publishing
        new_entry_ids =
          Set.new(@harvest_event.hierarchy_entry_ids_with_ancestors)
        TaxonConcept.unpublish_and_hide_by_entry_ids(
          new_entry_ids - old_entry_ids)
      end
      SolrCore::HierarchyEntries.reindex_hierarchy(@resource.hierarchy)
      # NOTE: This is a doozy of a method!
      @harvest_event.merge_matching_concepts
      # TODO: this really only needs to run if there are any traits in the
      # resource, so we should add a check for that (actually, I think we have
      # one...)
      EOL::Sparql::EntryToTaxonMap.create_graph(@resource)
      ActiveRecord::Base.connection.transaction do
        @resource.rebuild_taxon_concept_names
      end
      ActiveRecord::Base.connection.transaction do
        @harvest_event.sync_collection
      end
      @harvest_event.index_for_site_search
      @harvest_event.index_new_data_objects
      # TODO: make sure the harvest event is marked as published!
      @resource.update_attributes(resource_status_id:
        ResourceStatus.published.id)
      @resource.save_resource_contributions
      denormalize
      EOL.log("Completed publish of #{resource.title}")
      true
    end
  end
end
