class Hierarchy
  class ConceptAssignment
    def self.assign_for_hierarchy(hierarchy)
      assigner = self.new(hierarchy)
      assigner.assign
    end

    def initialize(hierarchy)
      @hierarchy = hierarchy
      @compared = []
      @confirmed_exclusions = {}
      @entries_matched = []
      @superceded = {}
    end

    # NOTE: this used to use DB transactions, but A) it was doing it wrong
    # (nested), and B) it did them "every 50 batches", which is awkward and...
    # well... useless anyway. I am going to do this WITHOUT A TRANSACTION. Deal
    # with it.
    def assign
      EOL.log_call
      # PHP: "looking up which hierarchies might have nodes in preview mode this
      # will save time later on when we need to check published vs preview taxa"
      lookup_preview_harvests
      get_confirmed_exclusions
      # TODO: this is slow; once we have harvesting ported, we can ensure that
      # it is corrected for each harvest, which is adequate. In that case,
      # simply remove this fix_counts:
      HierarchyEntry.counter_culture_fix_counts
      # TODO: DON'T hard-code this (this is GBIF Nub Taxonomy). Instead, add an
      # attribute to hierarchies called "never_merge_concepts" and check that.
      # Also make sure curators can set that value from the resource page.
      hierarchies = Hierarchy.where(["id NOT in (?)", 129]).
        order("hierarchy_entries_count DESC")
      # This is REALLY WEIRD (and lame), but it's what PHP did; This is, again,
      # a GBIF Nub taxonomy. The only effect this has is to make it last in the
      # list of hierarchies to compare. ...I haven't worked through this enough
      # to decide whether that means it's less likely to match (if it's matched
      # once, will it not match again?), so perhaps that's the intent. Perhaps
      # it is not worth sorting by entry count; perhaps the curators should
      # choose the order in which they are matched, if that's the case.
      hierarchies.find { |h| h.id == 800 }.hierarchy_entries_count = 1
      hierarchies.each do |other_hierarchy|
        # "Incomplete" hierarchies (e.g.: Flickr) actually can have multiple
        # entries that are actuall the "same", so we need to compare those to
        # themselves; otherwise, skip:
        next if @hierarchy.id == other_hierarchy.id && @hierarchy.complete?
        next if already_compared?(@hierarchy.id, other_hierarchy.id)
        compare_hierarchies(@hierarchy, other_hierarchy)
      end
    end

    private

    # TODO: break up, this is ginormous.
    def compare_hierarchies(h1, h2)
      (hierarchy1, hierarchy2) = fewer_entries_first(h1, h2)
      EOL.log("Comparing hierarchy #{hierarchy1.id} (#{hierarchy1.label}; "\
        "#{hierarchy1.hierarchy_entries_count} entries) to #{hierarchy2.id} "\
        "(#{hierarchy2.label}; #{hierarchy2.hierarchy_entries_count} "\
        "entries)")

      solr = SolrCore::HierarchyEntryRelationships.new
      # TODO: add (relationship:name OR confidence:[0.25 TO *]) [see below]

      entries = [] # Just to prevent weird infinite loops below. :\
      begin
        page ||= 0
        page += 1
        # NOTE: This is a REALLY slow query. ...Which sucks. :\ Yes, even for Solr... it takes a VERY long time.
        response = solr.paginate(query,
          options.merge(page: page, per_page: 10000))
        # TODO: error-checking that solr response; sample "responseHeader":
        # {"status"=>0, "QTime"=>14641, "params"=>{"sort"=>"relationship etc",
        # "wt"=>"ruby", "start"=>"0", "q"=>"blah blah", "rows"=>"10"}}
        response["response"]["docs"].each do |entry|
          handle_entry(entry)
        end
      end while entries.count > 0
    end

    def compare_hierarchies_query
      visible_id = Visibility.get_visible.id
      preview_id = Visibility.get_preview.id
      query = "hierarchy_id_1:#{hierarchy1.id} AND "\
        "(visibility_id_1:#{visible_id} OR visibility_id_1:#{preview_id}) "\
        "AND hierarchy_id_2:#{hierarchy2.id} AND "\
        "(visibility_id_2:#{visible_id} OR visibility_id_2:#{preview_id}) "\
        "AND same_concept:false"

      query
    end

    def compare_hierarchies_options
      # YOU WERE HERE
      { sort: "relationship asc, visibility_id_1 asc, "\
        "visibility_id_2 asc, confidence desc, hierarchy_entry_id_1 asc, "\
        "hierarchy_entry_id_2 asc"}
    end

    def handle_entry(entry)
      # Sample "entry": { "hierarchy_entry_id_1"=>47111837,
      # "taxon_concept_id_1"=>71511, "hierarchy_id_1"=>949,
      # "visibility_id_1"=>1, "hierarchy_entry_id_2"=>20466468,
      # "taxon_concept_id_2"=>71511, "hierarchy_id_2"=>107,
      # "visibility_id_2"=>0, "same_concept"=>true, "relationship"=>"name",
      # "confidence"=>1.0 }
      # TODO: move this criterion to the solr query (see above):
      return(nil) if entry["relationship"] == 'syn' && entry["confidence"] < 0.25
      id1 = entry["hierarchy_entry_id_1"]
      tc_id1 = entry["taxon_concept_id_1"]
      id2 = entry["hierarchy_entry_id_2"]
      tc_id2 = entry["taxon_concept_id_2"]
      # this node in hierarchy 1 has already been matched
      return(nil) if hierarchy1.complete? && @entries_matched.include?(id2)
      return(nil) if hierarchy2.complete? && @entries_matched.include?(id1)
      @entries_matched += [id1, id2]
      # PHP: "this comparison happens here instead of the query to ensure
      # the sorting is always the same if this happened in the query and the
      # entry was related to more than one taxa, and this function is run
      # more than once then we'll start to get huge groups of concepts - all
      # transitively related to one another"
      return(nil) if tc_id1 == tc_id2
      tc_id1 = follow_supercedure_cached(tc_id1)
      tc_id2 = follow_supercedure_cached(tc_id2)
      # NOTE: yes, PHP did this check again here. I wouldn't have, but I
      # don't know if the problem explained above would continue to happen.
      # I doubt it but it's only one quick check, so not worth the risk:
      return(nil) if tc_id1 == tc_id2
      # NOTE: the #find method follows supercedure
      tc_id1 = follow_supercedure(tc_id1)
      tc_id2 = follow_supercedure(tc_id2)
      return(nil) if tc_id1 == tc_id2
      EOL.log("Comparing entry #{id1} (hierarchy #{hierarchy1.id}) "\
        "with #{id2} (hierarchy #{hierarchy2.id})", prefix: "?")
      # PHP: "compare visible entries to other published entries"
      if entry_published_in_hierarchy?(1, entry, hierarchy1)
        EOL.log("SKIP: concept #{id2} published in hierarchy of #{id1}",
          prefix: ".")
        return(nil)
      end
      if entry_published_in_hierarchy?(2, entry, hierarchy2)
        EOL.log("SKIP: concept #{tc_id1} published in hierarchy "\
          "#{hierarchy2.id}", prefix: ".")
        return(nil)
      end
      if entry_preview_in_hierarchy?(1, entry, hierarchy1)
        EOL.log("SKIP: concept #{tc_id2} previewing in hierarchy "\
          "#{hierarchy1.id}", prefix: ".")
        return(nil)
      end
      if entry_preview_in_hierarchy?(2, entry, hierarchy2)
        EOL.log("SKIP: concept #{tc_id1} previewing in hierarchy "\
          "#{hierarchy2.id}", prefix: ".")
        return(nil)
      end
      if curators_denied_relationship?(entry)
        EOL.log("SKIP: merge of entry #{id1} (concept #{tc_id1}) with "\
          " #{id2} (concept #{tc_id2}) rejected by curator", prefix: ".")
          return(nil)
      end
      if affected = additional_hierarchy_affected_by_merge(tc_id1, tc_id2)
        EOL.log("SKIP: A merge of #{id1} (concept #{tc_id1}) and #{id2} "\
          "(concept #{tc_id2}) is not allowed by complete hierarchy "\
          "#{affected.label} (#{affected.id})", prefix: ".")
        return(nil)
      end
      EOL.log("MATCH: Concept #{tc_id1} = #{tc_id2}")
      #  - log the supercedure somewhere to be cleaned up, e.g.: in
      # CollectionItem.remove_superceded_taxa
      tc = TaxonConcept.merge_ids(tc_id1, tc_id2)
      @superceded[tc.id] = tc.supercedure_id
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
      CuratedHierarchyEntryRelationship.
        includes(:from_hierarchy_entry, :to_hierarchy_entry).
        where(equivalent: 0).
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

    # NOTE: we could query the DB to buld this full list. It takes about 30
    # seconds, and returns 32M results (as of this writing). ...We don't need
    # all of them, though, so doing this does save us quite a bit of time.
    def follow_supercedure_cached(id)
      while @superceded.has_key?(id)
        id = @superceded[id]
      end
      id
    end

    def follow_supercedure(id)
      tc = TaxonConcept.find(id)
      unless tc.id == id
        @superceded[id] = tc.id
      end
      tc.id
    end

    def fewer_entries_first(h1, h2)
      [h1, h2].sort_by(&:hierarchy_entries_count).reverse
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

    def entry_published_in_hierarchy?(which, entry, hierarchy)
      entry_has_vis_id_in_hierarchy?(which, entry, Visibility.get_visible.id,
        hierarchy)
    end

    def entry_preview_in_hierarchy?(which, entry, hierarchy)
      entry_has_vis_id_in_hierarchy?(which, entry, Visibility.get_preview.id,
        hierarchy)
    end

    def entry_has_vis_id_in_hierarchy?(which, entry, vis_id, hierarchy)
      other = which == 1 ? 2 : 1
      hierarchy.complete &&
        entry["visibility_id_#{which}"] == vis_id &&
        concept_has_vis_id_in_hierarchy(entry["taxon_concept_id_#{other}"],
          vis_id, hierarchy)
    end

    def concept_has_vis_id_in_hierarchy?(taxon_concept_id, vis_id, hierarchy)
      HierarchyEntry.exists?(taxon_concept_id: taxon_concept_id,
        hierarchy_id: hierarchy.id, visibility_id: vis_id)
    end

    def curators_denied_relationship?(entry)
      if @confirmed_exclusions.has_key?(entry["hierarchy_entry_id_1"])
        return confirmed_exclusions_matches?(entry["hierarchy_entry_id_1"],
          entry["taxon_concept_id_2"])
      elsif @confirmed_exclusions.has_key?(entry["hierarchy_entry_id_2"])
        return confirmed_exclusions_matches?(entry["hierarchy_entry_id_2"],
          entry["taxon_concept_id_1"])
      end
      false
    end

    def confirmed_exclusions_matches?(id, other_tc_id)
      @confirmed_exclusions[id1].each do |tc_id|
        tc_id = follow_supercedure_cached(tc_id)
        return true if tc_id == other_tc_id
      end
      false
    end

    # TODO: I don't get this. I've peeled it apart from the PHP method, and I'm
    # sure this represents what it was doing (much more elegantly and
    # efficiently). ...But this seems _incredibly_ common: one taxon concept has
    # an entry in a complete hierarchy and the other taxon concept also has an
    # entry in that hierarchy. ...Wouldn't that happen... almost always? [shrug]
    # Keeping it as-is, but: not sure we want this test! :|
    def additional_hierarchy_affected_by_merge(tc_id1, tc_id2)
      from_first = HierarchyEntry.visible.
        joins(:hierarchy).
        where(taxon_concept_id: tc_id1, hierarchy: { complete: true }).
        pluck(&:hierarchy_id)
      entry = HierarchyEntry.visible.
        includes(:hierarchy).
        where(taxon_concept_id: tc_id2, hierarchy_id: from_first).
        first
      return entry && entry.hierarchy
    end
  end
end
