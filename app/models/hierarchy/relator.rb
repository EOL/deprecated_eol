# This is a bit of a misnomer. ...This class could have been called
# HierarchyEntryRelationship::Relator (or the like), however it seemed more
# natural to be called from the context of a hierachy, so I'm putting it here.
# It creates HierarchyEntryRelationships, though.
class Hierarchy
  # TODO: scores are stored as floats... this is dangerous, and we
  # don't do anything with them that warrants it (other than multiply, which can
  # be achieved other ways). Let's switch to using a 0-100 scale, which is more
  # stable.
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
      # We load this at runtime, so new ranks are read in:
      @rank_groups = Hash[ *(Rank.where("rank_group_id != 0").
        flat_map { |r| [ r.id, r.rank_group_id ] }) ]
      @hierarchy = hierarchy
      @new_entry_ids = options[:entry_ids]
      # TODO: Never used, currently; saving for later port work:
      @hierarchy_against = options[:against]
      @count = 0
      @solr = SolrCore::HierarchyEntries.new
      @relationships = Set.new
    end

    def relate
      EOL.log_call
      return false unless @hierarchy # TODO: necessary?
      if @new_entry_ids
        compare_entries_by_id
      else
        raise NotImplementedError.new("cannot relate without list of ids")
        # iterate_through_entire_hierarchy # not doing this now.
      end
      add_curator_assertions
      delete_existing_relationships
      insert_relationships
      reindex_relationships
    end

    private

    def compare_entries_by_id
      EOL.log_call
      group_size = 200 # Limited size due to sending Solr queries via POST.
      @new_entry_ids.in_groups_of(group_size, false) do |batch|
        response = @solr.
          select("hierarchy_id:#{@hierarchy.id} AND "\
          "id:(#{batch.join(" OR ")})", rows: group_size)
        response["response"]["docs"].each do |entry|
          compare_entry(entry)
        end
      end
    end

    # TODO: cleanup. :| TODO: Speed up. This is a very, very slow process, even
    # with a tiny test database. Definitely need to improve the algorithm, here.
    def compare_entry(entry)
      matches = []
      entry["rank_id"] ||= 0
      if entry["name"]
        # TODO: do we need to do any unencoding here, since it came from Solr?
        search_name = entry["name"]
        # PHP TODO: "what about subgenera?"
        search_canonical = ""
        # TODO: store surrogate flag... somewhere. Store virus value there too
        if ! Name.is_surrogate_or_hybrid?(search_name) &&
          ! entry_is_in_virus_kingdom?(entry) &&
          ! entry["canonical_form"].blank?
          search_canonical = entry["canonical_form"] # TODO: unencode?
        end
        search_canonical = "" if search_canonical =~ /virus$/
        query_or_clause = []
        query_or_clause << "canonical_form_string:\"#{search_canonical}\"" if
          search_canonical
        query_or_clause << "name:\"#{search_name}\""
        # TODO: should we add this? The PHP code had NO WAY of getting to this:
        if(false)
          query_or_clause << "synonym_canonical:\"#{search_canonical}\""
        end
        query = "(#{query_or_clause.join(" OR ")})"
        # TODO: Never used, currently; saving for later port work:
        query += " AND hierarchy_id:#{@hierarchy_against.id}" if
          @hierarchy_against
        # Complete hierarchies are not compared with themselves. Other (e.g.:
        # Flickr, which can have multiple occurrences of the "same" concept in
        # it) _do_ need to be compared with themselves.
        query += " NOT hierarchy_id:#{@hierarchy.id}" if @hierarchy.complete?
        # PHP: "don't relate NCBI to itself"
        # TODO: This should NOT be hard-coded:
        query += " NOT hierarchy_id:759" if @hierarchy.id == 1172
        query += " NOT hierarchy_id:1172" if @hierarchy.id == 759
        # TODO: make rows variable configurable
        response = @solr.select(query, rows: 400)
        matching_entries_from_solr = response["response"]["docs"]
        matching_entries_from_solr.each do |matching_entry|
          compare_entries_from_solr(entry, matching_entry)
        end
      else
        # This is caused by entries with only a canonical form. I'm not sure if
        # this is "right," but it is certainly "normal," so I'm not sure we
        # actually need to warn about it. I'm leaving this on for now, though,
        # to get a sense of frequency and possibly spark a conversation about
        # whether we should be doing something different. It seems so—the name
        # on an entry should be the preferred scientific name, so this error
        # implies we have entries with no such thing... which is... odd. Should
        # it just be the canonical form?
        EOL.log("WARNING: solr entry had no name: #{entry["id"]} "\
          "(#{entry["canonical_form"]})", prefix: "!")
      end
    end

    def entry_is_in_virus_kingdom?(entry)
      entry["kingdom"] &&
        (entry["kingdom"].downcase == "virus" ||
        entry["kingdom"].downcase == "viruses")
    end

    def compare_entries_from_solr(entry, matching_entry)
      matching_entry["rank_id"] ||= 0
      # TODO: why bother returning a value rather than just storing it?
      score = score_comparison(entry,
        matching_entry)
      if score
        store_relationship(entry["id"],
          matching_entry["id"], score)
      end
      # TODO: examine whether this is REALLY necessary.
      inverted_score = score_comparison(matching_entry,
        entry)
      if inverted_score
        store_relationship(matching_entry["id"],
          entry["id"], score)
      end
    end

    def score_comparison(from_entry, to_entry)
      return nil if from_entry["id"] == to_entry["id"]
      # TODO: this really, really should not happen:
      return nil if from_entry["name"].blank? || to_entry["name"].blank?
      # TODO: shouldn't need this because of the condition above. :|
      return nil if @hierarchy.complete? &&
        from_entry["hierarchy_id"] == @hierarchy.id &&
        to_entry["hierarchy_id"] == @hierarchy.id
      return nil if rank_ids_conflict?(from_entry["rank_id"],
        to_entry["rank_id"])
      synonym = false
      # PHP: "viruses are a pain and will not match properly right now"
      is_virus = from_entry["name"].downcase =~ /virus$/ ||
        to_entry["name"].downcase =~ /virus$/
      is_virus ||= virus_kingdom?(from_entry) || virus_kingdom?(to_entry)
      # nil, 0.5, or 1... TODO: that's not terribly elegant. Re-think.
      name_match = compare_names(from_entry, to_entry, is_virus)
      # If it's not a complete match (and not a virus), check for synonyms:
      if ! name_match && ! is_virus
        name_match = compare_synonyms(from_entry, to_entry)
        synonym = true if name_match > 0 # TODO: ensure this cant be nil
      end
      ancestry_match = compare_ancestries(from_entry, to_entry)
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
      if @rank_groups.has_key?(rid1) || @rank_groups.has_key?(rid2)
        @rank_groups[rid1] != @rank_groups[rid2]
      else
        rid1 && rid2 && rid1 != rid2
      end
    end

    def virus_kingdom?(entry)
      entry["kingdom"].try(:downcase) == 'virus' ||
        entry["kingdom"].try(:downcase) == 'viruses'
    end

    def compare_names(from_entry, to_entry, is_virus)
      return 1 if from_entry["name"] == to_entry["name"]
      return nil if is_virus # TODO: wrong place for this
      return 0.5 if from_entry["canonical_form"] && to_entry["canonical_form"] &&
        from_entry["canonical_form"] == to_entry["canonical_form"]
      return nil
    end

    def compare_synonyms(from_entry, to_entry)
      if synonymy_of(to_entry).include?(from_entry["name"]) ||
        synonymy_of(from_entry).include?(to_entry["name"])
        1
      elsif synonymy_of(to_entry).include?(from_entry["canonical_form"]) ||
        synonymy_of(from_entry).include?(to_entry["canonical_form"])
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
    def compare_ancestries(from_entry, to_entry)
      return nil if empty_ancestry?(from_entry)
      return nil if empty_ancestry?(to_entry)
      EOL.log("ancestors: #{from_entry["id"]} -> #{to_entry["id"]}")
      score = best_matching_weight(from_entry, to_entry)
      # TODO: logging. ...We need some kind of record that explains why matches
      # were made or refused for each pair. :|
      # Kingdoms only match if...
      if score == RANK_WEIGHTS["kingdom"]
        # We _only_ had kingdoms to work with...
        return score / 100 unless
          has_any_non_kingdom?(e1) && has_any_non_kingdom?(e2)
        # the rank of this entry is a kingdom, phylm, class, or order:
        # TODO: delete this unless SPG can explain it...
        kingdom_match_valid_1 =
          RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY.include?(from_entry["rank_id"])
        kingdom_match_valid_2 =
          RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY.include?(to_entry["rank_id"])
        return 0 unless allowed_to_match_at_kingdom_only?(from_entry, to_entry)
        return 0 if from_entry["rank_id"].blank? || to_entry["rank_id"].blank?
        # TODO: Wait, what? They aren't allowed to match if they are the same
        # rank? That does not make sense to me. :\ But it's what PHP did!
        return 0 if from_entry["rank_id"] == to_entry["rank_id"]
      end
      return score / 100
    end

    def best_matching_weight(from_entry, to_entry)
      RANK_WEIGHTS.sort_by { |k,v| - v }.each do |rank, weight|
        if from_entry[rank] && to_entry[rank] && from_entry[rank] == to_entry[rank]
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

    # TODO: I'm kind of going to great lengths here to scan existing
    # relationships... this would be much cleaner code if we stored a parallel
    # hash, keyed with the "key" below, and with the score as a value, but I'm
    # _slightly_ worried that this might use more memory and not be as
    # efficient... This works as-is (AFAICT), but it's sloppy code. Sorry.
    def store_relationship(from, to, score)
      type = score[:synonym] ? 'syn' : 'name'
      key = "#{from}, #{to}, '#{type}',"
      old_relationship = @relationships.find { |r| r[0..key.length - 1] == key }
      old_score = old_relationship && old_relationship.split(', ').last.to_f
      @relationships << "#{key} #{score[:score]}" unless
        old_score && old_score < score[:score]
    end

    def add_curator_assertions
      EOL.log_call
      # This is lame, and obfuscated... but these are how two relationships are
      # named when they join to the same table. ...So we use them for
      # specificity (but to otherwise avoid complex SQL):
      [ :hierarchy_entries,
        :to_hierarchy_entries_curated_hierarchy_entry_relationships
      ].each do |entry_in_hierarchy|
        CuratedHierarchyEntryRelationship.equivalent.
          joins(:from_hierarchy_entry, :to_hierarchy_entry).
          where(entry_in_hierarchy => { hierarchy_id: @hierarchy.id }).
          each do |cher|
          # NOTE: Yes, PHP stores both, but it used two queries (inefficiently):
          store_relationship(cher.hierarchy_entry_id_1,
            cher.hierarchy_entry_id_2, { score: 1, synonym: false })
          store_relationship(cher.hierarchy_entry_id_2,
            cher.hierarchy_entry_id_1, { score: 1, synonym: false })
        end
      end
    end

    # NOTE: since we've built all relationships to and from this hierarchy, we
    # can delete both from the DB:
    def delete_existing_relationships
      EOL.log_call
      @hierarchy.hierarchy_entry_ids.in_groups_of(6400, false) do |ids|
        HierarchyEntryRelationship.where(hierarchy_entry_id_1: ids).delete_all
        HierarchyEntryRelationship.where(hierarchy_entry_id_2: ids).delete_all
      end
    end

    def insert_relationships
      EOL.log_call
      EOL::Db.bulk_insert(HierarchyEntryRelationship,
        [ "hierarchy_entry_id_1", "hierarchy_entry_id_2",
          "relationship", "score" ],
        @relationships.to_a)
    end

    # NOTE: PHP did this before swapping the tmp tables (because it never did,
    # perhaps), so the code _there_ actually reads from the tmp table. That
    # didn't make sense to me (too convoluted), so I've moved it.
    def reindex_relationships
      EOL.log_call
      SolrCore::HierarchyEntryRelationships.
        reindex_entries_in_hierarchy(@hierarchy, @new_entry_ids)
    end
  end
end
