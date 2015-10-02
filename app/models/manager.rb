class Manager
  class << self
    # The main method of this class:
    def tend
      EOL.log_call
      if paused?
        # TODO - this is a good place for a rescue/throw pair.
        unless(pause)
          EOL.log("Harvesting pause exceeded wait time, exiting.")
          return false
        end
      end
      @batch ||= HarvestBatch.new
      resource = Resource.next
      if resource.nil? || @batch.complete?
        @batch.post_harvesting
        denormalize_tables
        rebuild_solr_if_needed
        @batch = HarvestBatch.new
      end
      if resource
        @batch.add(resource)
        resource.harvest_TODO # DO THIS LAST.
      else
        EOL.log("Finished")
      end
      true
    end

    def denormalize_tables
      EOL.log_call
      DataObjectsTaxonConceptsDenormalizer.denormalize
      # TODO: this is really silly. We should just handle this as we do the
      # harvest... no need to rebuild the WHOLE THING every time! Just silly.
      # Bah. ...Can't add that until we port harvesting, though.
      DataObjectsTableOfContent.rebuild
      # TODO:
      # PHP: "/top_images.php
      # PHP: // "/random_hierarchy_images.php
      # PHP: "/create_preferred_entries.php

      EOL.log("denormalize_tables finished", prefix: "#")
    end

    def pause
      count = 0
      while paused?
        # Only worth logging the pause once every half an hour...
        EOL.log("Harvesting paused, waiting...") if count % 30 == 0
        sleep(60)
        count += 1
        if count > 240 # We've waited 4 hours...
          return false
        end
      end
      EOL.log("Unpaused. Continuing.")
    end

    # TODO - Putting this in a method because I don't like how it was implemented.
    def paused?
      Resource.is_paused?
    end

    def rebuild_solr_if_needed
      if in_solr_rebuild_window?
        EOL.log("Rebuilding Solr indexes.")
        # TODO - Nice to make this a loop...
        solr = SolrCore::DataObjects.new
        solr.optimize
        solr = SolrCore::CollectionItems.new
        solr.optimize
        solr = SolrCore::HierarchyEntries.new
        solr.optimize
        solr = SolrCore::HierarchyEntryRelationship.new
        solr.optimize
        solr = SolrCore::SiteSearch.new
        solr.optimize
        EolConfig.where(parameter: 'last_solr_rebuild').
          update_all(value: Time.now.to_s)
      end
    end

    def in_solr_rebuild_window?
      last_rebuild = EolConfig.last_solr_rebuild
      return true if last_rebuild.nil?
      Time.now > Time.parse(last_rebuild) + 3.days &&
        [0,6].include?(last_rebuild.wday)
    end
  end
end
