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
      batch.post_harvesting
      optimize_solr_if_needed
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
