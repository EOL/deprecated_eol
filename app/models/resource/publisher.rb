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
      @event = resource.harvest_events.last
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
      EOL.log("PUBLISH: #{resource.title}", prefix: "{")
      unless options[:force]
        raise "Harvest event already published!" if @event.published?
        raise "Harvest event not complete!" unless @event.complete?
        raise "Publish flag not set!" unless @event.publish?
      end
      @event.publish
      # NOTE: the next two steps comprise the lion's share of publishing time.
      # NOTE: longest step:
      @resource.reindex_for_merges unless was_previewed
      # NOTE: second longest step:
      @event.merge_matching_concepts unless was_previewed
      @resource.rebuild_taxon_concept_names
      @event.sync_collection unless was_previewed
      @resource.create_mappings
      @resource.port_traits
      @event.index_for_site_search
      @event.index_new_data_objects
      @resource.mark_as_published
      @resource.save_resource_contributions
      denormalize
      EOL.log("PUBLISH DONE: #{resource.title}", prefix: "}")
      true
    end

    def denormalize
      @resource.hierarchy.insert_data_objects_taxon_concepts
      # TODO: this next command isn't technically enough. (it will work, but it
      # will leave zombie entries). We need to add a step that says "delete all
      # entries in dotoc where ids in (list of ids that were in previous event
      # but not this one)"
      @event.insert_dotocs
    end

    def reindex_and_merge
      @resource.reindex_for_merges
      @event.merge_matching_concepts
    end
  end
end
