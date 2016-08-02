class Hierarchy
  # This depends ENTIRELY on Hierarchy::Relator (q.v.) having completed first.
  class ConceptMerger
    def self.merges_for_hierarchy(hierarchy, options = {})
      assigner = self.new(hierarchy, options)
      assigner.merges_for_hierarchy
    end

    # Options:
    # to: one or more hierarchies to compare yours with
    # to_all: compare yours with all other hierarchies (deafult is just browsable)
    # ids: entry IDs to compare; default all entries in hierarchy
    # NOTE: to_all and ids are currently only used by developers on the
    # command-line.
    def initialize(hierarchy, options = {})
      EOL.log_call
      @hierarchy = hierarchy
      if options[:to]
        @hierarchies = Array(options[:to])
        [:col, :gbif, :iucn_structured_data, :ubio, :ncbi, :worms, :itis,
               :wikipedia].each do |h_name|
          if @hierarchies.delete(h_name)
            @hierarchies << Hierarchy.send(h_name)
          end
        end
        @hierarchies << @hierarchy # Necessary. Please don't remove.
      else
        @hierarchies = Hierarchy.order("hierarchy_entries_count DESC")
        @hierarchies = @hierarchies.browsable unless options[:to_all]
      end
      @ids = {}
      Array(options[:ids]).each { |id| @ids[id] = true }
      @debug = options[:debug]
      @entries_matched = {}
      @compared = {}
      @merges = {} # The merges we do
      @superceded = {} # ALL superceded ids we encounter, ever (saves queries)
      @visible_id = Visibility.get_visible.id
      @preview_id = Visibility.get_preview.id
      @per_page = Rails.configuration.solr_relationships_page_size.to_i
      @solr = SolrCore::HierarchyEntryRelationships.new
      @exclusions = CuratedHierarchyEntryRelationship.exclusions
      @preview_events_by_hierarchy = HarvestEvent.preview_events_by_hierarchy
      fix_entry_counts if fix_entry_counts_needed?
    end

    # NOTE: I am going to do this WITHOUT A DB TRANSACTION. Deal with it.
    def merges_for_hierarchy
      EOL.log("Start merges for hierarchy #{@hierarchy.id} "\
        "#{@hierarchy.display_title} (#{@hierarchy.hierarchy_entries_count} "\
        "entries)")
      @hierarchies.each_with_index do |other_hierarchy, index|
        EOL.log("...to #{other_hierarchy.id} (#{other_hierarchy.label}; "\
          "#{other_hierarchy.hierarchy_entries_count} entries): "\
          "#{index + 1} of #{@hierarchies.size}")
        # "Incomplete" hierarchies (e.g.: Flickr) actually can have multiple
        # entries that are actually the "same", so we need to compare those to
        # themselves; otherwise, skip:
        next if @hierarchy.id == other_hierarchy.id && @hierarchy.complete?
        compare_hierarchies(@hierarchy, other_hierarchy)
      end
      EOL.log("Preparing to merge #{@merges.keys.size} taxa into "\
        "#{@merges.values.sort.uniq.size} targets.")
      num_merges = merge_taxa || 0
      CollectionItem.remove_superceded_taxa(@merges) unless num_merges <= 0
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
      EOL.log "Fix of entry counts is needed, please wait..."
      HierarchyEntry.counter_culture_fix_counts
    end

    def compare_hierarchies(h1, h2)
      (hierarchy1, hierarchy2) = fewer_entries_first(h1, h2)
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
        "#{hierarchy2.id} (new total: #{@merges.keys.count} matches)")
    end

    def get_page_from_solr(hierarchy1, hierarchy2, page)
      # NOTE: this was *really* banging on Solr, so we're rate-limiting it quite
      # a bit:
      sleep(1)
      response = @solr.paginate(compare_hierarchies_query(hierarchy1,
        hierarchy2), compare_hierarchies_options(page))
      rhead = response["responseHeader"]
      if rhead["QTime"] && rhead["QTime"].to_i > 1000
        EOL.log("SLOW (#{rhead["QTime"]}ms): Hierarchy::ConceptMerger#"\
          "get_page_from_solr for #{rhead["params"]["rows"]} results",
          prefix: "!")
        EOL.log("gporfs query: #{rhead["params"]["q"]}", prefix: ".")
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
        unless @ids.has_key?(relationship["hierarchy_entry_id_1"]) ||
          @ids.has_key?(relationship["hierarchy_entry_id_2"])
          EOL.log("Not included in IDs to match.") if @debug
          return nil
        end
      end
      if relationship["relationship"] == "syn" &&
        relationship["confidence"] < 0.25
        EOL.log("Synonym with low confidence (#{relationship["confidence"]}) #{relationship.inspect}") if @debug
        return(nil)
      end
      (id1, tc_id1, hierarchy1, id2, tc_id2, hierarchy2) =
        *assign_local_vars_from_relationship(relationship)
      if hierarchy1.complete? && @entries_matched.has_key?(id2)
        EOL.log("Already matched id2=#{id2} (and heirarchy1 complete)") if @debug
        return(nil)
      end
      if hierarchy2.complete? && @entries_matched.has_key?(id1)
        EOL.log("Already matched id1=#{id1} (and heirarchy2 complete)") if @debug
        return(nil)
      end
      @entries_matched[id1] = true
      @entries_matched[id2] = true
      # PHP: "this comparison happens here instead of the query to ensure the
      # sorting is always the same if this happened in the query and the entry
      # was related to more than one taxa, and this function is run more than
      # once then we'll start to get huge groups of concepts - all transitively
      # related to one another" ...Sounds to me like we're doing something
      # wrong, if this is true. :\
      if tc_id1 == tc_id2
        EOL.log("Same concept (#{tc_id1})") if @debug
        return(nil)
      end
      tc_id1 = follow_supercedure_cached(tc_id1)
      tc_id2 = follow_supercedure_cached(tc_id2)
      # This seems to be a bug (in Solr?), but we have to catch it!
      if tc_id1 == 0
        EOL.log("Concept 1 had no ID after supercedure #{relationship.inspect}") if @debug
        return(nil)
      end
      if tc_id2 == 0
        EOL.log("Concept 2 had no ID after supercedure #{relationship.inspect}") if @debug
        return(nil)
      end
      if tc_id1 == tc_id2
        EOL.log("Same concept (#{tc_id1}), after supercedure #{relationship.inspect}") if @debug
        return(nil)
      end
      if separate_concepts?(relationship)
        EOL.log("Separate concepts: #{relationship.inspect}") if @debug
        return(nil)
      end
      if excluded_relationship?(relationship)
        EOL.log("Curators exluded relationship: #{relationship.inspect}") if @debug
        return(nil)
      end
      if additional_hierarchy_affected_by_merge(tc_id1, tc_id2)
        EOL.log("Hierarchy asserts separate concepts: #{relationship.inspect}") if @debug
        return(nil)
      end
      (new_id, old_id) = [tc_id1, tc_id2].sort
      @merges[old_id] = new_id
      @superceded[old_id] = new_id
    end

    def merge_taxa
      begin
        return TaxonConcept::Merger.in_bulk(@merges)
      rescue => e
        EOL.log("ERROR: Merging failed. Merge map: #{@merges.inspect}")
        raise(e)
      end
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

    def separate_concepts?(relationship)
      (id1, tc_id1, hierarchy1, id2, tc_id2, hierarchy2) =
        *assign_local_vars_from_relationship(relationship)
      if hierarchy1.complete?
        if visible_entry_in_hierarchy?(1, relationship)
          EOL.log("#{hierarchy1.label} claims these are separate concepts") if
            @debug
          return true
        end
        # HE.exists?(concept: 2, hierarchy: 1, visibility: preview)
        if preview_entry_in_hierarchy?(1, relationship)
          EOL.log("#{hierarchy1.label} claims these are separate concepts") if
            @debug
          return true
        end
      end
      if hierarchy2.complete?
        # HE.exists?(concept: 1, hierarchy: 2, visibility: visible)
        if visible_entry_in_hierarchy?(2, relationship)
          EOL.log("#{hierarchy2.label} claims these are separate concepts") if
            @debug
          return true
        end
        # HE.exists?(concept: 1, hierarchy: 2, visibility: preview)
        if preview_entry_in_hierarchy?(2, relationship)
          EOL.log("#{hierarchy2.label} claims these are separate concepts") if
            @debug
          return true
        end
      end
      false
    end

    def visible_entry_in_hierarchy?(which, relationship)
      entry_with_vis_id_in_hierarchy?(which, relationship, @visible_id)
    end

    def preview_entry_in_hierarchy?(which, relationship)
      return false unless @preview_events_by_hierarchy.has_key?(
        relationship["hierarchy_id_#{which}"])
      entry_with_vis_id_in_hierarchy?(which, relationship, @preview_id)
    end

    def entry_with_vis_id_in_hierarchy?(which, relationship, vis_id)
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
      @compared.has_key?(compared_key(id1, id2))
    end

    # This doesn't actually matter, just needs to be consistent.
    def compared_key(id1, id2)
      [id1, id2].sort.join("&")
    end

    def mark_as_compared(id1, id2)
      @compared[compared_key(id1, id2)] = true
    end

    def excluded_relationship?(relationship)
      if @exclusions.has_key?(relationship["hierarchy_entry_id_1"])
        return exclusions_matches?(relationship["hierarchy_entry_id_1"],
          relationship["taxon_concept_id_2"])
      elsif @exclusions.has_key?(relationship["hierarchy_entry_id_2"])
        return exclusions_matches?(relationship["hierarchy_entry_id_2"],
          relationship["taxon_concept_id_1"])
      end
      false
    end

    def exclusions_matches?(id, other_tc_id)
      @exclusions[id].each do |tc_id|
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
