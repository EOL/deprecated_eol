class Hierarchy
  # This depends ENTIRELY on Hierarchy::Relator (q.v.) having completed first.
  class ConceptMerger
    def self.merges_for_hierarchy(hierarchy)
      assigner = self.new(hierarchy)
      assigner.merges_for_hierarchy
    end

    def initialize(hierarchy, options = {})
      @hierarchy = hierarchy
      @compared = []
      @all_hierarchies = options[:all_hierarchies]
      @ids = Array(options[:ids])
      @confirmed_exclusions = {}
      @entries_matched = []
      @merges = {} # The merges we do
      @superceded = {} # ALL superceded ids we encounter, ever (saves queries)
      @visible_id = Visibility.get_visible.id
      @preview_id = Visibility.get_preview.id
      @per_page = Rails.configuration.solr_relationships_page_size.to_i
      @solr = SolrCore::HierarchyEntryRelationships.new
    end

    # NOTE: I am going to do this WITHOUT A DB TRANSACTION. Deal with it.
    def merges_for_hierarchy
      EOL.log("Start merges for hierarchy #{@hierarchy.id} "\
        "#{@hierarchy.display_title} (#{@hierarchy.hierarchy_entries_count} "\
        "entries)")
      fix_entry_counts if fix_entry_counts_needed?
      lookup_preview_harvests
      get_confirmed_exclusions
      # TODO: DON'T hard-code this (this is GBIF Nub Taxonomy). Instead, add an
      # attribute to hierarchies called "never_merge_concepts" and check that.
      # Also make sure curators can set that value from the resource page.
      # .where(["id NOT in (?)", 129]).
      @hierarchies = Hierarchy.order("hierarchy_entries_count DESC")
      @hierarchies = @hierarchies.browsable unless @all_hierarchies
      @hierarchies.each_with_index do |other_hierarchy, index|
        EOL.log("...to #{other_hierarchy.id} (#{other_hierarchy.label}; "\
          "#{other_hierarchy.hierarchy_entries_count} entries): "\
          "#{index + 1} of #{@hierarchies.size}")
        # "Incomplete" hierarchies (e.g.: Flickr) actually can have multiple
        # entries that are actually the "same", so we need to compare those to
        # themselves; otherwise, skip:
        next if @hierarchy.id == other_hierarchy.id && @hierarchy.complete?
        # TODO: this shouldn't even be required.
        next if already_compared?(@hierarchy.id, other_hierarchy.id)
        compare_hierarchies(@hierarchy, other_hierarchy)
      end
      EOL.log("Preparing to merge #{@merges.keys.size} taxa into "\
        "#{@merges.values.sort.uniq.size} targets.")
      TaxonConcept::Merger.in_bulk(@merges)
      CollectionItem.remove_superceded_taxa(@merges)
      EOL.log("Completed merges for hierarchy #{@hierarchy.display_title}")
    end

    private

    # This is not the greatest way to check accuracy, but catches most problem
    # scenarios and is faster than always fixing:
    def fix_entry_counts_needed?
      Hierarchy.where(hierarchy_entries_count: 0).find_each do |hier|
        return true if hier.hierarchy_entries.count > 0
      end
      false
    end

    def fix_entry_counts
      HierarchyEntry.counter_culture_fix_counts
    end

    def compare_hierarchies(h1, h2)
      (hierarchy1, hierarchy2) = fewer_entries_first(h1, h2)
      # TODO: add (relationship:name OR confidence:[0.25 TO *]) [see below]
      # TODO: Set?
      entries = [] # Just to prevent weird infinite loops below. :\
      begin
        page ||= 0
        page += 1
        entries = get_page_from_solr(hierarchy1, hierarchy2, page)
        entries.each do |relationship|
          begin
            merge_matching_concepts(relationship)
          rescue => e
            EOL.log("FAILED merge_matching_concepts:", prefix: "!")
            EOL.log(relationship.inspect, prefix: "!")
            raise(e)
          end
        end
      end while entries.size > 0
      EOL.log("Completed comparing hierarchy #{hierarchy1.id} to "\
        "#{hierarchy2.id}")
    end

    def get_page_from_solr(hierarchy1, hierarchy2, page)
      response = @solr.paginate(compare_hierarchies_query(hierarchy1,
        hierarchy2), compare_hierarchies_options(page))
      # NOTE: this was *really* banging on Solr, so we're rate-limiting it quite
      # a bit (I will also reduce the page size by half-ish):
      sleep(1)
      rhead = response["responseHeader"]
      if rhead["QTime"] && rhead["QTime"].to_i > 1000
        EOL.log("gporfs query: #{rhead["q"]}", prefix: ".")
        EOL.log("gporfs Request took #{rhead["QTime"]}ms", prefix: ".")
      end
      response["response"]["docs"]
    end

    def compare_hierarchies_query(hierarchy1, hierarchy2)
      query = "hierarchy_id_1:#{hierarchy1.id} AND "\
        "(visibility_id_1:#{@visible_id} OR visibility_id_1:#{@preview_id}) "\
        "AND hierarchy_id_2:#{hierarchy2.id} AND "\
        "(visibility_id_2:#{@visible_id} OR visibility_id_2:#{@preview_id}) "\
        "AND same_concept:false AND -confidence:0"
      query
    end

    def compare_hierarchies_options(page)
      { sort: "relationship asc, visibility_id_1 asc, "\
        "visibility_id_2 asc, confidence desc, hierarchy_entry_id_1 asc, "\
        "hierarchy_entry_id_2 asc"}.merge(page: page, per_page: @per_page)
    end

    def merge_matching_concepts(relationship)
      # Sample "relationship": { "hierarchy_entry_id_1"=>47111837,
      # "taxon_concept_id_1"=>71511, "hierarchy_id_1"=>949,
      # "visibility_id_1"=>1, "hierarchy_entry_id_2"=>20466468,
      # "taxon_concept_id_2"=>71511, "hierarchy_id_2"=>107,
      # "visibility_id_2"=>0, "same_concept"=>true, "relationship"=>"name",
      # "confidence"=>1.0 }
      unless @ids.empty?
        return(nil) unless
          @ids.include?(relationship["hierarchy_entry_id_1"]) ||
          @ids.include?(relationship["hierarchy_entry_id_2"])
      end
      return(nil) if relationship["relationship"] == "syn" &&
        relationship["confidence"] < 0.25
      (id1, tc_id1, hierarchy1, id2, tc_id2, hierarchy2) =
        *assign_local_vars_from_relationship(relationship)
      # skip if the node in the hierarchy has already been matched:
      return(nil) if hierarchy1.complete? && @entries_matched.include?(id2)
      return(nil) if hierarchy2.complete? && @entries_matched.include?(id1)
      @entries_matched += [id1, id2]
      # PHP: "this comparison happens here instead of the query to ensure the
      # sorting is always the same if this happened in the query and the entry
      # was related to more than one taxa, and this function is run more than
      # once then we'll start to get huge groups of concepts - all transitively
      # related to one another" ...Sounds to me like we're doing something
      # wrong, if this is true. :\
      return(nil) if tc_id1 == tc_id2
      tc_id1 = follow_supercedure_cached(tc_id1)
      tc_id2 = follow_supercedure_cached(tc_id2)
      # This seems to be a bug (in Solr?), but we have to catch it!
      return(nil) if tc_id1 == 0 or tc_id2 == 0
      return(nil) if tc_id1 == tc_id2
      working_on = "#{hierarchy1.id}->#{id1}->#{tc_id1} vs "\
        "#{hierarchy2.id}->#{id2}->#{tc_id2}"
      return(nil) if concepts_of_one_already_in_other?(relationship)
      if curators_denied_relationship?(relationship)
        return(nil)
      end
      if affected = additional_hierarchy_affected_by_merge(tc_id1, tc_id2)
        return(nil)
      end
      (new_id, old_id) = [tc_id1, tc_id2].sort
      @merges[old_id] = new_id
      @superceded[old_id] = new_id
      EOL.log("MATCH: Concept #{old_id} => #{new_id}")
    end

    # TODO: This really hints and an object, doesn't it? :S See
    # Hierarchy::EntryRelationship for WIP
    def assign_local_vars_from_relationship(relationship)
      [ relationship["hierarchy_entry_id_1"],
        relationship["taxon_concept_id_1"],
        find_hierarchy(relationship["hierarchy_id_1"]),
        relationship["hierarchy_entry_id_2"],
        relationship["taxon_concept_id_2"],
        find_hierarchy(relationship["hierarchy_id_2"]) ]
    end

    def find_hierarchy(id)
      hierarchy = @hierarchies.find { |h| h.id == id }
      if hierarchy.nil?
        hierarchy = Hierarchy.find(id)
        @hierarchies << hierarchy
      end
      hierarchy
    end

    def lookup_preview_harvests
      @latest_preview_events_by_hierarchy = {}
      resources = Resource.select("resources.id, resources.hierarchy_id, "\
        "MAX(harvest_events.id) max").
        joins(:harvest_events).
        group(:hierarchy_id)
      HarvestEvent.unpublished.where(id: resources.map { |r| r["max"] }).
        each do |event|
        resource = resources.find { |r| r["max"] == event.id }
        @latest_preview_events_by_hierarchy[resource.hierarchy_id] = event
      end
    end

    def get_confirmed_exclusions
      CuratedHierarchyEntryRelationship.not_equivalent.
        includes(:from_hierarchy_entry, :to_hierarchy_entry).
        # Some of the entries have gone missing! Skip those:
        select { |ce| ce.from_hierarchy_entry && ce.to_hierarchy_entry }.
        each do |cher|
        from_entry = cher.from_hierarchy_entry.id
        from_tc = cher.from_hierarchy_entry.taxon_concept_id
        to_entry = cher.to_hierarchy_entry.id
        to_tc = cher.to_hierarchy_entry.taxon_concept_id
        @confirmed_exclusions[from_entry] ||= []
        @confirmed_exclusions[from_entry] << to_tc
        @confirmed_exclusions[to_entry] ||= []
        @confirmed_exclusions[to_entry] << from_tc
      end
    end

    def concepts_of_one_already_in_other?(relationship)
      (id1, tc_id1, hierarchy1, id2, tc_id2, hierarchy2) =
        *assign_local_vars_from_relationship(relationship)
      if hierarchy1.complete?
        # HE.exists?(concept: 2, hierarchy: 1, visibility: visible)
        if entry_published_in_hierarchy?(1, relationship)
          # EOL.log("SKIP: concept #{tc_id2} published in hierarchy of #{id1}",
          #   prefix: ".")
          return true
        end
        # HE.exists?(concept: 2, hierarchy: 1, visibility: preview)
        if entry_preview_in_hierarchy?(1, relationship)
          # EOL.log("SKIP: concept #{tc_id2} previewing in hierarchy "\
          #   "#{hierarchy1.id}", prefix: ".")
          return true
        end
      end
      if hierarchy2.complete?
        # HE.exists?(concept: 1, hierarchy: 2, visibility: visible)
        if entry_published_in_hierarchy?(2, relationship)
          # EOL.log("SKIP: concept #{tc_id1} published in hierarchy "\
          #   "#{hierarchy2.id}", prefix: ".")
          return true
        end
        # HE.exists?(concept: 1, hierarchy: 2, visibility: preview)
        if entry_preview_in_hierarchy?(2, relationship)
          # EOL.log("SKIP: concept #{tc_id1} previewing in hierarchy "\
          #   "#{hierarchy2.id}", prefix: ".")
          return true
        end
      end
      false
    end

    def entry_published_in_hierarchy?(which, relationship)
      entry_has_vis_id_in_hierarchy?(which, relationship, @visible_id)
    end

    def entry_preview_in_hierarchy?(which, relationship)
      return false unless @latest_preview_events_by_hierarchy.has_key?(
        relationship["hierarchy_id_#{which}"])
      entry_has_vis_id_in_hierarchy?(which, relationship, @preview_id)
    end

    def entry_has_vis_id_in_hierarchy?(which, relationship, vis_id)
      other = which == 1 ? 2 : 1
      relationship["visibility_id_#{which}"] == vis_id &&
        HierarchyEntry.exists?(
          taxon_concept_id: relationship["taxon_concept_id_#{other}"],
          hierarchy_id: relationship["hierarchy_id_#{which}"],
          visibility_id: vis_id)
    end

    # NOTE: we could query the DB to buld this full list, using
    # TaxonConcept.superceded. It takes about 30 seconds, and returns 32M
    # results (as of this writing). ...We don't need all of them, though, so
    # doing this does potentially save us a bit of time.... I think. I guess it
    # depends on how many TaxonConcepts we call #find for. TODO: we could just
    # have a "supercedure" table. ...That would actually be pretty handy, though
    # it would be another case of having to pay attention to a denormalized
    # table, and I'm not sure it's worth that, either. Worth checking, I
    # suppose.
    def follow_supercedure_cached(id)
      new_id = if @superceded.has_key?(id) && @superceded[id] != 0
        @superceded[id]
      else
        follow_supercedure(id)
      end
      while @superceded.has_key?(new_id) && @superceded[id] != 0
        new_id = @superceded[new_id]
      end
      new_id
    end

    def follow_supercedure(id)
      tc = TaxonConcept.find(id)
      unless tc.id == id || tc.id == 0
        @superceded[id] = tc.id
      end
      tc.id
    end

    def fewer_entries_first(h1, h2)
      [h1, h2].sort_by(&:hierarchy_entries_count)
    end

    def already_compared?(id1, id2)
      @compared.include?(compared_key(id1, id2))
    end

    # This doesn't actually matter, just needs to be consistent.
    def compared_key(id1, id2)
      [id1, id2].sort.join("&")
    end

    def mark_as_compared(id1, id2)
      @compared << compared_key(id1, id2)
    end

    def curators_denied_relationship?(relationship)
      if @confirmed_exclusions.has_key?(relationship["hierarchy_entry_id_1"])
        return confirmed_exclusions_matches?(relationship["hierarchy_entry_id_1"],
          relationship["taxon_concept_id_2"])
      elsif @confirmed_exclusions.has_key?(relationship["hierarchy_entry_id_2"])
        return confirmed_exclusions_matches?(relationship["hierarchy_entry_id_2"],
          relationship["taxon_concept_id_1"])
      end
      false
    end

    def confirmed_exclusions_matches?(id, other_tc_id)
      @confirmed_exclusions[id].each do |tc_id|
        tc_id = follow_supercedure_cached(tc_id)
        return true if tc_id == other_tc_id
      end
      false
    end

    # One taxon concept has an entry in a complete hierarchy and the other taxon
    # concept also has an entry in that hierarchy. ...Merging them would violate
    # the other hierarchy's assertion that they are different entities.
    def additional_hierarchy_affected_by_merge(tc_id1, tc_id2)
      from_first = HierarchyEntry.visible.
        joins(:hierarchy).
        where(taxon_concept_id: tc_id1, hierarchies: { complete: true }).
        pluck(:hierarchy_id)
      HierarchyEntry.visible.
        where(taxon_concept_id: tc_id2, hierarchy_id: from_first).
        exists?
    end
  end
end
