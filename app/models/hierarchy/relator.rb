# This is a bit of a misnomer. ...This class could have been called
# HierarchyEntryRelationship::Relator (or the like), however it seemed more
# natural to be called from the context of a hierachy, so I'm putting it here.
# It creates HierarchyEntryRelationships, though.
class Hierarchy
  # This depends entirely on the entries being indexed in
  # SolrCore::HierarchyEntries (q.v.)! TODO: scores are stored as floats... this
  # is dangerous, and we don't do anything with them that warrants it (other
  # than multiply, which can be achieved other ways). Let's switch to using a
  # 0-100 scale, which is more stable.
  class Relator
    # NOTE: PHP actually had a bug (!) where this was _only_ Kingdom, but the
    # intent was clearly supposed to be this, so I'm going with it: TODO - this
    # should be in the DB, anyway. :\
    RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY = [
      Rank.kingdom.try(:id),
      Rank.phylum.try(:id),
      Rank.class_rank.try(:id),
      Rank.order.try(:id)
    ].compact
    RANK_WEIGHTS = { "family" => 100, "order" => 80, "class" => 60,
      "phylum" => 40, "kingdom" => 20 }

    # I am not going to freak out about the fact that TODO: this needs to be in
    # the database. I've lost my energy to freak out about such things. :|
    GOOD_SYNONYMY_HIERARCHY_IDS = [
      123, # WORMS
      143, # Fishbase
      622, # IUCN
      636, # Tropicos
      759, # NCBI
      787, # ReptileDB
      860, # Avibase
      903, # ITIS
      949  # COL 2012
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
      @browsable = Hierarchy.browsable
      @new_entry_ids = options[:entry_ids]
      # TODO: Never used, currently; saving for later port work:
      @hierarchy_against = options[:against]
      @count = 0
      @all_hierarchies = options[:all_hierarchies]
      @per_page = Rails.configuration.solr_relationships_page_size.to_i
      @per_page = 1000 unless @per_page > 0
      @solr = SolrCore::HierarchyEntries.new
      @scores = {}
    end

    def relate
      return false unless @hierarchy # TODO: necessary?
      compare_entries
      add_curator_assertions
      delete_existing_relationships
      insert_relationships
      reindex_relationships
    end

    private

    def compare_entries
      EOL.log("Comparing entries for hierarchy ##{@hierarchy.id}")
      begin
        page ||= 0
        page += 1
        entries = get_page_from_solr(page)
        entries.each do |entry|
          begin
            compare_entry(entry) if @new_entry_ids.include?(entry["id"])
          rescue => e
            EOL.log("Failed on entry ##{entry["id"]} (page #{page})")
            raise e
          end
        end
      end while entries.count > 0
    end

    def get_page_from_solr(page)
      # This query is very fast, even at high page numbers:
      response = @solr.paginate("hierarchy_id:#{@hierarchy.id}",
        page: page, per_page: @per_page)
      sleep(0.3) # Less of a hit to production, please!
      rhead = response["responseHeader"]
      if rhead["QTime"] && rhead["QTime"].to_i > 100
        EOL.log("relator query: #{rhead["q"]}", prefix: ".")
        EOL.log("relator request took #{rhead["QTime"]}ms", prefix: ".")
      end
      if page == 1 && response["response"] && response["response"]["numFound"]
        EOL.log("Total of #{response["response"]["numFound"]} entries")
      end
      response["response"]["docs"]
    end

    def metaquote(string)
      string.gsub(/\\/, "\\\\\\\\").gsub(/"/, "\\\"")
    end

    # TODO: cleanup. :|
    def compare_entry(entry)
      matches = []
      entry["rank_id"] ||= 0
      if entry["name"]
        # TODO: do we need to do any unencoding here, since it came from Solr?
        search_name = metaquote(entry["name"])
        # PHP TODO: "what about subgenera?"
        search_canonical = ""
        # TODO: store surrogate flag... somewhere. Store virus value there too
        if ! Name.is_surrogate_or_hybrid?(search_name) &&
          ! entry_is_in_virus_kingdom?(entry) &&
          ! entry["canonical_form"].blank?
          search_canonical = metaquote(entry["canonical_form"])
        end
        search_canonical = "" if search_canonical =~ /virus$/
        query_or_clause = []
        query_or_clause << "canonical_form_string:\"#{search_canonical}\"" unless
          search_canonical.blank?
        query_or_clause << "name:\"#{search_name}\""
        # TODO: should we add this? The PHP code had NO WAY of getting to this:
        if (false)
          query_or_clause << "synonym_canonical:\"#{search_canonical}\""
        end
        query = "(#{query_or_clause.join(" OR ")})"
        if @all_hierarchies
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
        else
          h_ids = @browsable
          h_ids = h_ids.where(["id != ?", @hierarchy.id]) if
            @hierarchy.complete?
          conditions = h_ids.pluck(:id).map { |id| "hierarchy_id:#{id}" }
          query += " AND (#{conditions.join(" OR ")})"
        end
        # TODO: make rows variable configurable
        response = @solr.select(query, rows: 400)
        # NOTE: this was WAAAAAY too hard on Solr, we needed to gate it:
        sleep(0.3)
        rhead = response["responseHeader"]
        if rhead["QTime"] && rhead["QTime"].to_i > 200
          EOL.log("compare query: #{query}", prefix: ".")
          EOL.log("compare request took #{rhead["QTime"]}ms", prefix: ".")
        end
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
        EOL.log("WARNING: solr entry with canonical form only: #{entry["id"]} "\
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
      score = score_comparison(entry, matching_entry)
      if score
        store_score(entry["id"], matching_entry["id"], score)
      end
      # TODO: examine whether this is REALLY necessary.
      inverted_score = score_comparison(matching_entry, entry)
      if inverted_score
        store_score(matching_entry["id"], entry["id"], score)
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
        synonym = name_match > 0
      end
      ancestry_match = compare_ancestries(from_entry, to_entry)
      total_score = if name_match.nil?
        0
      elsif ancestry_match.nil?
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
      if @rank_groups.has_key?(rid1) && @rank_groups.has_key?(rid2)
        @rank_groups[rid1] != @rank_groups[rid2]
      else
        rid1 && rid1 != 0 && rid2 && rid2 != 0 && rid1 != rid2
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
      score = best_matching_weight(from_entry, to_entry)
      # TODO: logging. ...We need some kind of record that explains why matches
      # were made or refused for each pair. :|
      # Kingdoms only match if...
      if score == RANK_WEIGHTS["kingdom"]
        # We _only_ had kingdoms to work with...
        return score / 100 unless
          has_any_non_kingdom?(from_entry) && has_any_non_kingdom?(to_entry)
        # the rank of this entry is a kingdom, phylm, class, or order:
        # TODO: delete this unless SPG can explain it...
        kingdom_match_valid_1 =
          RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY.include?(from_entry["rank_id"])
        kingdom_match_valid_2 =
          RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY.include?(to_entry["rank_id"])
        return 0 unless allowed_to_match_at_kingdom_only?([from_entry, to_entry])
        return 0 if from_entry["rank_id"].blank? || to_entry["rank_id"].blank?
        # TODO: Wait, what? They aren't allowed to match if they are the same
        # rank (and they only match at kingom)? That does not make sense to me. :\
        # But it's what PHP did!
        return 0 if from_entry["rank_id"] == to_entry["rank_id"]
      end
      return score.to_f / 100
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
      entry.values_at(*RANK_WEIGHTS.keys).all? { |v| v.blank? }
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

    def store_score(from, to, score)
      type = score[:synonym] ? 'syn' : 'name'
      key = "#{from},#{to},'#{type}'"
      unless @scores.has_key?(key) && @scores[key] < score[:score]
        @scores[key] = score[:score]
      end
      size = @scores.size
      EOL.log("#{size} relationships...", prefix: ".") if size % 10_000 == 0
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
          # Some of the entries have gone missing! Skip those:
          select { |ce| ce.from_hierarchy_entry && ce.to_hierarchy_entry }.
          each do |cher|
          # NOTE: Yes, PHP stores both, but it used two queries (inefficiently):
          store_score(cher.hierarchy_entry_id_1,
            cher.hierarchy_entry_id_2, { score: 1, synonym: false })
          store_score(cher.hierarchy_entry_id_2,
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
      relationships = @scores.keys.map do |key|
        "#{key},#{@scores[key]}"
      end
      EOL::Db.bulk_insert(HierarchyEntryRelationship,
        [:hierarchy_entry_id_1, :hierarchy_entry_id_2, :relationship, :score],
        relationships.to_a)
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
