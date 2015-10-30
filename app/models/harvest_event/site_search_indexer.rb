class HarvestEvent
  class SiteSearchIndexer
    def self.index(event)
      indexer = self.new(event)
      indexer.index
    end

    def initialize(event)
      @harvest_event = event
      @solr = SolrCore::SiteSearch.new
    end

    # NOTE: This _requires_ an associated flattened hierarchy. the PHP code
    # actually called the hierarchy flattener here. I don't want to do that; by
    # the time we're calling this, we've already done it (at least so far as has
    # been ported). TODO: really, we should be able to check whether that's been
    # done and call it if not; worth adding a flag to the DB to indicate that.
    def index_harvest_event(event)
      @solr.index_type(DataObject, @harvest_event.new_data_object_ids)
      @solr.index_type(TaxonConcept, HierarchyEntry.where(
        id: @harvest_event.new_hierarchy_entry_ids).pluck(:taxon_concept_id))
    end

    def insert_batch(klass, ids) # TODO: this is what gets called, sooo...
      objects = call("get_#{klass.underscore.pluralize}")
      ids.in_groups_of(1000, false) do |batch|
        @solr.delete("resource_type:#{klass} AND "\
          "resource_id:(#{batch.join(" OR ")})")
      end
      if objects
      end
      @solr.commit
      # // add new ones if available
      # if(isset($this->objects) && $this->objects)
      # {
      #     if($class_name == 'TaxonConcept') $this->send_concept_objects_to_solr();
      #     else $this->solr->send_attributes_in_bulk($this->objects);
      # }
      # $this->solr->commit();

    end
  end
end
