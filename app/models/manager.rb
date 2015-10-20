class Manager
  class << self
    # The main method of this class:
    def tend(options = {})
      EOL.log_call
      options[:max_runs] = 30
      batch ||= HarvestBatch.new
      while resource = Resource.next && ! batch.complete?
        if paused?
          begin
            pause
          rescue EOL::Exceptions::HarvestPauseTimeExceeded => e
            EOL.log("Harvesting pause exceeded wait time, exiting.")
            return false
          end
        end
        EOL.log("Manager found resource #{resource.id} to harvest...",
          prefix: '@')
        batch.add(resource)
        resource.harvest
      end
      EOL.log("Finished with batch of #{batch.count} resources", prefix: '@')
      EOL.log("(maximum count)", prefix: '.') if batch.maximum_count?
      EOL.log("(timed out, started at #{batch.start_time})", prefix: '.') if
        batch.time_out?
      batch.post_harvesting
      denormalize_tables
      optimize_solr_if_needed
    end

    def denormalize_tables
      EOL.log_call
      DataObjectsTaxonConceptsDenormalizer.denormalize
      # TODO: this is really silly. We should just handle this as we do the
      # harvest... no need to rebuild the WHOLE THING every time! Just silly.
      # Bah. ...Can't add that until we port harvesting, though.
      DataObjectsTableOfContent.rebuild
      # TODO: this is not an efficient algorithm. We should change this to store
      # the scores in the DB as well as some kind of tree-structure of taxa
      # (which could also be used elsewhere!), and then build things that way;
      # we should also actually store the sort order in this table, rather than
      # overloading the id (!); that would allow us to update the table only as
      # needed, based on what got harvested (i.e.: a list of data objects
      # inserted could be used to figure out where they lie in the sort, and
      # update the orders as needed based on that—much faster.)
      TopImage.rebuild
      RandomHierarchyImage.create_random_images_from_rich_taxa
      TaxonConceptPreferredEntry.rebuild
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
          raise EOL::Exceptions::HarvestPauseTimeExceeded.new
        end
      end
      EOL.log("Unpaused. Continuing.")
    end

    # TODO - Putting this in a method because I don't like how it was implemented.
    def paused?
      Resource.is_paused?
    end

    def optimize_solr_if_needed
      if in_solr_rebuild_window?
        EOL.log("Rebuilding Solr indexes.")
        # TODO - Nice to make this a loop...
        [SolrCore::DataObjects,
          SolrCore::CollectionItems,
          SolrCore::HierarchyEntries,
          SolrCore::HierarchyEntryRelationships,
          SolrCore::SiteSearch].each do |klass|
          solr = klass.optimize
        end
        EolConfig.where(parameter: 'last_solr_rebuild').
          update_all(value: Time.now.to_s)
      end
    end

    def in_solr_rebuild_window?
      last_rebuild = EolConfig.last_solr_rebuild
      return true if last_rebuild.nil?
      Time.now > Time.parse(last_rebuild) + 3.days &&
        [0,6].include?(Time.now.wday)
    end
  end
end
