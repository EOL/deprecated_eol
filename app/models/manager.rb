class Manager
  class < self
    def tend
      log_start_TODO
      handle_pauses_TODO
      @batch ||= HarvestBatch.new
      resource = get_next_resource_TODO
      if resource.nil? || @batch.complete?
        @batch.post_harvesting
        denormalize_tables_TODO
        rebuild_solr_if_needed
        @batch = HarvestBatch.new
      end
      if resource
        @batch.add(resource)
        resource.harvest_TODO
      else
        log_finished_TODO
      end
    end

    def rebuild_solr_if_needed
      last_rebuild = EolConfig.last_solr_rebuild
      if in_solr_rebuild_window?(last_rebuild)
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
        EolConfig.create(parameter: 'last_solr_rebuild', value: Time.now.to_s)
      end
    end

    def in_solr_rebuild_window?(last_rebuild)
      return true if last_rebuild.nil?
      Time.now > Time.parse(last_rebuild) + 3.days &&
        [0,6].include?(last_rebuild.wday)
    end
  end
end
