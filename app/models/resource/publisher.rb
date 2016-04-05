class Resource
  class Publisher
    attr_reader :resource, :harvest_event

    def self.publish(resource, options = {})
      publisher = self.new(resource)
      publisher.publish(options)
    end

    def self.preview(resource)
      publisher = self.new(resource)
      publisher.preview
    end

    def initialize(resource)
      @resource = resource
      @harvest_event = resource.harvest_events.last
      raise "No hierarchy!" unless @resource.hierarchy
    end

    # A "light" version of publishing for resources that we keep in "preview
    # mode" NOTE that we don't have "preview" for TraitBank. NOTE: This
    # _requires_ that the flattened hierarchy have been rebuilt when this is
    # called.
    def preview
      reindex_and_merge
      sync_collection
      denormalize
      true
    end

    # NOTE: yes, PHP used multiple transactions. I suppose it was to avoid
    # locking the DB for too long, but I wonder if it was wise? TODO: consider
    # whether we acutally _need_ transactions! ...We can assume the HEs that
    # we're working on are not being touched... the worst that might happen is
    # curation of something that gets missed here, but we might be able to
    # capture that in another way. NOTE: This _requires_ that the flattened
    # hierarchy have been rebuilt when this is called.
    def publish(options = {})
      was_previewed = options[:previewed]
      EOL.log("PUBLISH: #{resource.title}")
      raise "Harvest event already published!" if @harvest_event.published?
      raise "Harvest event not complete!" unless @harvest_event.complete?
      raise "Publish flag not set!" unless @harvest_event.publish?
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
        @harvest_event.publish_objects
        @harvest_event.mark_as_published
        new_entry_ids =
          Set.new(@harvest_event.hierarchy_entry_ids_with_ancestors)
        TaxonConcept.unpublish_and_hide_by_entry_ids(
          new_entry_ids - old_entry_ids)
      end
      reindex_and_merge unless was_previewed
      EOL::Sparql::EntryToTaxonMap.create_graph(@resource)
      ActiveRecord::Base.connection.transaction do
        @resource.rebuild_taxon_concept_names
      end
      sync_collection unless was_previewed
      @harvest_event.index_for_site_search
      @harvest_event.index_new_data_objects
      @resource.create_mappings
      @resource.port_traits
      @harvest_event.update_attribute(:published_at, Time.now)
      @resource.update_attribute(:resource_status_id,
        ResourceStatus.published.id)
      @resource.save_resource_contributions
      denormalize
      EOL.log_return
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

    def reindex_and_merge
      SolrCore::HierarchyEntries.reindex_hierarchy(@resource.hierarchy)
      # NOTE: This is a doozy of a method! It's the largest piece of publishing.
      @harvest_event.merge_matching_concepts
    end

    def sync_collection
      ActiveRecord::Base.connection.transaction do
        @harvest_event.sync_collection
      end
    end
  end
end
