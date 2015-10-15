class Hierarchy
  class Relator

    # Quick test (be sure you know what you're doing):
    if (false)
      h = Hierarchy.last
      Hierarchy::Relator.relate(h, entries: h.hierarchy_entry_ids)
    end

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
      if @entry_ids
        compare_entries_by_id
      else
        raise NotImplementedError.new("cannot relate without list of ids")
        # iterate_through_entire_hierarchy # not doing this now.
      end
      add_curator_assertions
      insert_relationships
      reindex_relationships
    end

    private

    def compare_entries_by_id
      EOL.log_call
      group_size = 200 # Limited size due to sending Solr queries via POST.
      @entry_ids.in_groups_of(group_size, false) do |batch|
        response = @solr.
          select("hierarchy_id:#{@hierarchy.id} AND "\
          "id:(#{batch.join(" OR ")})", rows: group_size)
        # TODO: error-handling.
        response["response"]["docs"].each do |entry|
          compare_entry(entry)
        end
      end
    end

    def compare_entry(entry)
      matches = []
      entry["rank_id"] ||= 0
      if entry["name"]
        # TODO: do we need to do any unencoding here, since it came from Solr?
        search_name = entry["name"]
        # PHP TODO: "what about subgenera?"
        # TODO: clean up
        if Name.is_surrogate_or_hybrid?(search_name)
          search_canonical = ""
        elsif entry["kingdom"] &&
          entry["kingdom"].downcase == "virus" ||
          entry["kingdom"].downcase == "viruses"
          search_canonical = ""
        elsif canonical_form_string = entry["canonical_form"]
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
        matching_entries_from_solr.each do |matching_entry|
          matching_entry["rank_id"] ||= 0
          score = compare_entries_from_solr(entry,
            matching_entry)
          if score
            store_relationship(entry["id"],
              matching_entry["id"], score)
          end
          inverted_score = compare_entries_from_solr(matching_entry,
            entry)
          if inverted_score
            store_relationship(matching_entry["id"],
              entry["id"], score)
          end
        end
      else
        EOL.log("WARNING: solr entry had no name: #{entry}",
          prefix: "!")
      end
    end

    def compare_entries_from_solr(e1, e2) # TODO (from_entry, to_entry)
      return nil if e1["id"] == e2["id"]
      return nil if e1["name"].blank? || e2["name"].blank?
      return nil if @hierarchy.complete? &&
        e1["hierarchy_id"] == @hierarchy.id &&
        e2["hierarchy_id"] == @hierarchy.id
      return nil if rank_ids_conflict?(e1["rank_id"], e2["rank_id"])
      synonym = false
      # PHP: "viruses are a pain and will not match properly right now"
      is_virus = e1["name"].downcase =~ /virus$/ ||
        e2["name"].downcase =~ /virus$/
      is_virus ||= virus_kingdom?(e1) || virus_kingdom?(e2)
      name_match = compare_names(e1, e2, is_virus) # nil, 0.5, or 1... TODO :|
      # If it's not a complete match (and not a virus), check for synonyms:
      if ! name_match && ! is_virus
        name_match = compare_synonyms(e1, e2)
        synonym = true if name_match > 0
      end
      ancestry_match = compare_ancestries(e1, e2)
      total_score = if ancestry_match.nil?
        # One of the ancestries was totally empty:
        name_match * 0.5
      elsif ancestry_match > 0
        # Ancestry was reasonable match:
        name_match * ancestry_match
      else
        0 # TODO: should we even _store_ scores of 0?!
      end
      { score: total_score, synonym: synonym }
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
      type = score[:synonym] ? 'syn' : 'name'
      @relationships << "#{from}, #{to}, '#{type}', #{score}"
    end

    def add_curator_assertions
      EOL.log_call
      # This is lame, and obfuscated... but these are how two relationships are
      # named when they join to the same table. ...So we use them for
      # specificity (but to otherwise avoid complex SQL):
      join_table_names = [
        :hierarchy_entries,
        :to_hierarchy_entries_curated_hierarchy_entry_relationships
      ]
      [1, 2].each do |entry_in_hierarchy|
        CuratedHierarchyEntryRelationship.equivalent.
          joins(:from_hierarchy_entry, :to_hierarchy_entry).
          where(join_table_names[entry_in_hierarchy-1] =>
            { hierarchy_id: @hierarchy.id }).
          each do |cher|
          # Yes, PHP stores both, but it used two queries (inefficiently):
          store_relationship(cher.hierarchy_entry_id_1,
            cher.hierarchy_entry_id_2, { score: 1, synonym: false })
          store_relationship(cher.hierarchy_entry_id_2,
            cher.hierarchy_entry_id_1, { score: 1, synonym: false })
        end
      end
    end

    def insert_relationships
      EOL.log_call
      EOL::Db.with_tmp_tables(HierarchyEntryRelationship) do
        EOL::Db.bulk_insert(HierarchyEntryRelationship,
          [ "hierarchy_entry_id_1", "hierarchy_entry_id_2",
            "relationship", "score" ],
          @relationships,
          tmp: true, ignore: true)
        # Errr... in PHP, the tables never get swapped! That can't be right, so
        # I'm doing it:
        EOL::Db.swap_tmp_table(HierarchyEntryRelationship)
      end
    end

    # NOTE: PHP did this before swapping the tmp tables (because it never did,
    # perhaps), so the code _there_ actually reads from the tmp table. That
    # didn't make sense to me (too convoluted), so I've moved it.
    def reindex_relationships
      EOL.log_call
      SolrCore::HierarchyEntryRelationships.
        reindex_entries_in_hierarchy(@hierarchy, @entry_ids)
    end
  end
end
