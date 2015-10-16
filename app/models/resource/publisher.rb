class Resource
  class Publisher
    attr_reader :resource, :harvest_event

    def self.publish(resource)
      publisher = self.new(resource)
      publisher.publish
    end

    def initialize(resource)
      @resource = resource
      @harvest_event = HarvestEvent.where(resource_id: @resource.id).last
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
      ActiveRecord::Base.connection.transaction do
        raise "No harvest event!" unless @harvest_event
        raise "Harvest event already published!" if @harvest_event.published?
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
      # TODO: rename:
      TaxonConcept.post_harvest_cleanup(@resource)
      SolrCore::HierarchyEntries.reindex_hierarchy(@resource.hierarchy)
      # NOTE: this is the doozy (TODO: rename)!!! This is where new concepts are
      # created and entries are mapped to existing concepts. This is it, folks:
      # harvesting. ...And we call it "publishing". Weird. Not what I expected.
      @harvest_event.relate_hierarchy_entries
      @resource.hierarchy.assign_concepts
      create_taxon_mappings_graph
      # YOU WERE HERE
      ActiveRecord::Base.connection.transaction do
        @resuorce.update_names_TODO # $this->update_names();
        # That gets all of the TCs from this harvest_event (not ancestors), then
        # runs Tasks::update_taxon_concept_names($taxon_concept_ids), which is
        # very, very long and complicated, but rebuilds taxon_concept_names
      end
      ActiveRecord::Base.connection.transaction do
        @harvest_event.create_collection_TODO # $harvest_event->create_collection();
      end
      @harvest_event.index_for_search_TODO # $harvest_event->index_for_search();
      # TODO: make sure the harvest event is marked as published!
      @resource.update_attributes(resource_status_id:
        ResourceStatus.published.id)
      @resource.save_resource_contributions
    end

    # TODO: This doesn't feel like the right place for this method; too much
    # Sparql knowledge. Not sure where is "right," probably a new class.
    def create_taxon_mappings_graph
      sparql = EOL::Sparql::Connection.new
      mappings_graph = sparql.mappings_graph_name(@resource)
      triples = Set.new
      HierarchyEntry.has_identifier.
        where(hierarchy_id: @resource.hierarchy_id).
        select("id, identifier, taxon_concept_id").find_each do |entry|
        triples <<
          "<#{sparql.entry_uri(entry, resource: @resource)}> "\
          "dwc:taxonConceptID "\
          "<#{sparql.taxon_concept_uri(entry.taxon_concept_id)}>"
      end
      sparql.delete_graph(mappings_graph)
      sparql.insert_into_graph(mappings_graph, triples)
    end
  end
end
