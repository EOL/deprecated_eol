class Hierarchy
  class Relator

    # NOTE: PHP actually had a bug (!) where this was _only_ Kingdom, but the
    # intent was clearly supposed to be this, so I'm going with it: TODO - this
    # should be in the DB, anyway. :\
    RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY = [
      Rank.kingdom.id,
      Rank.phylum.id,
      Rank.class_rank.id,
      Rank.order.id
    ]
    RANK_WEIGHTS = { "family" => 100, "order" => 80, "class" => 60,
      "phylum" => 40, "kingdom" => 20 }
    RANK_GROUPS = Hash[ *(Rank.where("rank_group_id != 0").
      flat_map { |r| [ r.id, r.rank_group_id ] }) ]
    # I am not going to freak out about the fact that TODO: this needs to be in
    # the database. I've lost my energy to freak out about such things. :|
    GOOD_SYNONYMY_HIERARCHY_IDS = [
      903, # ITIS
      759, # NCBI
      123, # WORMS
      949, # COL 2012
      787, # ReptileDB
      622, # IUCN
      636, # Tropicos
      143, # Fishbase
      860  # Avibase
    ]

    def self.relate(hierarchy, options = {})
      relator = self.new(hierarchy, options)
      relator.relate
    end

    def initialize(hierarchy, options = {})
      @hierarchy = hierarchy
      @entry_ids = options[:entries]
      # TODO: Never used, currently; saving for later port work:
      @hierarchy_against = options[:against]
      @count = 0
      @solr = SolrCore::HierarchyEntries.new
      @relationships = [] # This is what PL used to write to file.
    end

    def relate
      return false unless @hierarchy # TODO: necessary?
      time_comparisons_started = Time.now # TODO: remove
      if @entry_ids
        iterate_through_selected_entries
      else
        raise NotImplementedError.new("cannot relate without list of ids")
        # iterate_through_entire_hierarchy_TODO # not doing this now.
      end
      # YOU WERE HERE:
      finalize_process_TODO
    end

    # TODO: private somewhere here

    # TODO: rename
    def iterate_through_selected_entries
      EOL.log_call
      group_size = 200 # Limited size due to sending Solr queries via POST.
      @entry_ids.in_groups_of(group_size, false) do |batch|
        response = @solr.
          select("hierarchy_id:#{@hierarchy.id} AND "\
          "id:(#{batch.join(" OR ")})", rows: group_size)
        # TODO: error-handling.
        iterate_through_entries(response["response"]["docs"])
      end
    end

    def iterate_through_entries(entries) # TODO: rename
      hierarchy_entry_matches = {}
      entries.each do |entry_from_solr|
        # TODO: rename return val
        matches = start_comparing_entry_from_solr(entry_from_solr)
        hierarchy_entry_matches[entry_from_solr["id"]] = {}
        matches.each do |match|
          hierarchy_entry_matches[entry_from_solr["id"]][match[:id]] =
            match[:score]
        end
      end
      write_relationships_to_temp_file(hierarchy_entry_matches)
    end

    def start_comparing_entry_from_solr(entry_from_solr) # TODO: renames
      matches = []
      entry_from_solr["rank_id"] ||= 0
      if entry_from_solr["name"]
        # TODO: do we need to do any unencoding here, since it came from Solr?
        search_name = entry_from_solr["name"]
        # PHP TODO: "what about subgenera?"
        # TODO: clean up
        if Name.is_surrogate_or_hybrid?(search_name)
          search_canonical = ""
        elsif entry_from_solr["kingdom"] &&
          entry_from_solr["kingdom"].downcase == "virus" ||
          entry_from_solr["kingdom"].downcase == "viruses"
          search_canonical = ""
        elsif canonical_form_string = entry_from_solr["canonical_form"]
          search_canonical = canonical_form_string # TODO: unencode?
        else
          search_canonical = ""
        end
        search_canonical = "" if search_canonical =~ /virus$/
        query_bits = []
        query_bits << "canonical_form_string:\"#{search_canonical}\"" if
          search_canonical
        query_bits << "name:#{search_name}"
        # TODO: should we add this? The PHP code had NO WAY of getting to this:
        if(false)
          query_bits << "synonym_canonical:\"#{search_canonical}\""
        end
        query = "(#{query_bits.join(" OR ")})"
        # TODO: Never used, currently; saving for later port work:
        query += " AND hierarchy_id:#{@hierarchy_against.id}" if
          @hierarchy_against
        # TODO: What's this?
        query += " NOT hierarchy_id:#{@hierarchy.id}" if
          @hierarchy.complete?
        # TODO: This should NOT be hard-coded, jerk:
        # PHP: "don't relate NCBI to itself"
        query += " NOT hierarchy_id:759" if @hierarchy.id == 1172
        query += " NOT hierarchy_id:1172" if @hierarchy.id == 759
        response = @solr.
          select(query, rows: 400) # TODO: generalize rows variable
        # TODO: error-handling
        matching_entries_from_solr = response["response"]["docs"]
        matching_entries_from_solr.each do |matching_entry_from_solr|
          matching_entry_from_solr["rank_id"] ||= 0
          score = compare_entries_from_solr(entry_from_solr,
            matching_entry_from_solr)
          if score
            store_relationship(entry_from_solr["id"],
              matching_entry_from_solr["id"], score)
          end
          inverted_score = compare_entries_from_solr(matching_entry_from_solr,
            entry_from_solr)
          if inverted_score
            store_relationship(matching_entry_from_solr["id"],
              entry_from_solr["id"], score)
          end
        end
      else
        EOL.log("WARNING: solr entry had no name: #{entry_from_solr}",
          prefix: "!")
      end
    end

if(false)
  rel = Hierarchy::Relator.new(Hierarchy.last)
  e1 = { "id" => 1 }
  e2 = { "id" => 1 }
  # Should return nil:
  rel.compare_entries_from_solr(e1, e2)
  e1 = { "id" => 1, "name" => "" }
  e2 = { "id" => 2, "name" => "foo" }
  # Should return nil:
  rel.compare_entries_from_solr(e1, e2)
  e1 = { "id" => 1, "name" => "bar", "hierarchy_id" => @hierarchy.id }
  e2 = { "id" => 2, "name" => "foo", "hierarchy_id" => @hierarchy.id }
  # Should return nil:
  rel.compare_entries_from_solr(e1, e2)
  e1 = { "id" => 1, "name" => "bar", "hierarchy_id" => 1,
    "rank_id" => TranslatedRank.find_by_label("gen.").rank_id }
  e2 = { "id" => 2, "name" => "foo", "hierarchy_id" => 2,
    "rank_id" => TranslatedRank.find_by_label("species").rank_id }
  # Should return nil
  rel.compare_entries_from_solr(e1, e2)
  e1 = { "id" => 1, "name" => "bar", "hierarchy_id" => 1,
    "rank_id" => 123 }
  e2 = { "id" => 2, "name" => "foo", "hierarchy_id" => 2,
    "rank_id" => 234 }
  # Should return ... lots more to test, above is template...
  rel.compare_entries_from_solr(e1, e2)
end

    def compare_entries_from_solr(e1, e2) # TODO (from_entry, to_entry)
      return nil if e1["id"] == e2["id"]
      return nil if e1["name"].blank? || e2["name"].blank?
      return nil if @hierarchy.complete? &&
        e1["hierarchy_id"] == @hierarchy.id &&
        e2["hierarchy_id"] == @hierarchy.id
      return nil if rank_ids_conflict?(e1["rank_id"], e2["rank_id"])
      # PHP: "viruses are a pain and will not match properly right now"
      is_virus = e1["name"].downcase =~ /virus$/ ||
        e2["name"].downcase =~ /virus$/
      is_virus ||= virus_kingdom?(e1) || virus_kingdom?(e2)
      name_match = compare_names(e1, e2, is_virus) # nil, 0.5, or 1... TODO :|
      # If it's not a complete match (and not a virus), check for synonyms:
      if ! name_match && ! is_virus
        name_match = compare_synonyms(e1, e2) * -1 # TODO :| on the -1
      end
      ancestry_match = compare_ancestries(e1, e2)
      total_score = if ancestry_match.nil?
        # One of the ancestries was totally empty:
        name_match * 0.5
      elsif ancestry_match > 0
        # Ancestry was reasonable match:
        name_match * ancestry_match
      else
        0
      end
      total_score
    end

    def rank_ids_conflict?(rid1, rid2)
      if RANK_GROUPS.has_key?(rid1) || RANK_GROUPS.has_key?(rid2)
        RANK_GROUPS[rid1] != RANK_GROUPS[rid2]
      else
        rid1 && rid2 && rid1 != rid2
      end
    end

    def virus_kingdom?(entry)
      entry["kingdom"].try(:downcase) == 'virus' ||
        entry["kingdom"].try(:downcase) == 'viruses'
    end

    def compare_names(e1, e2, is_virus)
      return 1 if e1["name"] == e2["name"]
      return nil if is_virus
      return 0.5 if e1["canonical_form"] && e2["canonical_form"] &&
        e1["canonical_form"] == e2["canonical_form"]
      return nil
    end

    def compare_synonyms(e1, e2)
      if synonymy_of(e2).include?(e1["name"]) ||
        synonymy_of(e1).include?(e2["name"])
        1
      elsif synonymy_of(e2).include?(e1["canonical_form"]) ||
        synonymy_of(e1).include?(e2["canonical_form"])
        0.5
      else
        0
      end
    end

    def synonymy_of(entry)
      if GOOD_SYNONYMY_HIERARCHY_IDS[entry["hierarchy_id"]] && entry["synonym"]
        entry["synonym"]
      else
        []
      end
    end

    # "check each rank in order of priority and return the respective weight on
    # match"
    def compare_ancestries(e1, e2)
      return nil if empty_ancestry?(e1)
      return nil if empty_ancestry?(e2)
      score = best_matching_weight(e1, e2)
      # Kingdoms only match if...
      if score == RANK_WEIGHTS["kingdom"]
        # We _only_ had kingdoms to work with...
        return score / 100 unless has_any_non_kingdom?(e1)
        return score / 100 unless has_any_non_kingdom?(e2)
        # the rank of this entry is a kingdom, phylm, class, or order:
        kingdom_match_valid_1 =
          RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY.include?(e1["rank_id"])
        kingdom_match_valid_2 =
          RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY.include?(e2["rank_id"])
        return 0 unless allowed_to_match_at_kingdom_only?(e1, e2)
        return 0 if e1["rank_id"].blank? || e2["rank_id"].blank?
        # TODO: Wait, what? They aren't allowed to match if they are the same
        # rank? That does not make sense to me. :\ But it's what PHP did!
        return 0 if e1["rank_id"] == e2["rank_id"]
      end
      return score / 100
    end

    def best_matching_weight(e1, e2)
      RANK_WEIGHTS.sort_by { |k,v| - v }.each do |rank, weight|
        if e1[rank] && e2[rank] && e1[rank] == e2[rank]
          return weight
        end
      end
      return 0
    end

    def empty_ancestry?(entry)
      entry.values_at(*RANK_WEIGHTS.keys).any? { |v| ! v.blank? }
    end

    def has_any_non_kingdom?(entry)
      ranks = RANK_WEIGHTS.keys
      ranks.delete("kingdom")
      entry.values_at(*ranks).any? { |v| ! v.blank? }
    end

    def allowed_to_match_at_kingdom_only?(entries)
      Array(entries).each do |entry|
        return false unless
          RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY.include?(entry["rank_id"])
      end
      true
    end

    def store_relationship(from, to, score)
      type = 'name'
      # TODO: fucking stupid, change
      if score < 0
        score = score.abs
        type = 'syn'
      end
      @relationships << [nil, from, to, type, score]
    end
  end
end
