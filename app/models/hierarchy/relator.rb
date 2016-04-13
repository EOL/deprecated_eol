# This is a bit of a misnomer. ...This class could have been called
# HierarchyEntryRelationship::Relator (or the like), however it seemed more
# natural to be called from the context of a hierachy, so I'm putting it here.
# It creates HierarchyEntryRelationships, though.
class Hierarchy
  # This depends entirely on the entries being indexed in
  # SolrCore::HierarchyEntries (q.v.)! TODO: scores are stored as floats... this
  # is dangerous, and we don't do anything with them that warrants it (other
  # than multiply, which can be achieved other ways). Let's switch to using a
  # 0-100 scale, which is more stable. NOTE: this is called by
  # Hierarchy#reindex_and_merge_ids
  class Relator
    # NOTE: PHP actually had a bug (!) where this was _only_ Kingdom, but the
    # intent was clearly supposed to be this, so I'm going with it: TODO - this
    # should be in the DB, anyway. :\
    kingdom_friendly_ids = []
    [:kingdom, :phylum, :class_rank, :order].each do |rank_name|
      kingdom_friendly_ids += Rank.where(rank_group_id:
        Rank.send(rank_name).rank_group_id).pluck(:id)
    end
    kingdom_friendly_index = {}
    kingdom_friendly_ids.each { |id| kingdom_friendly_index[id] = true }
    RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY = kingdom_friendly_index
    # NOTE: Genus is low because, presumedly, a binomial will always match at
    # the Genus if it's matched the name. :\
    RANK_WEIGHTS = { "genus" => 0.5, "family" => 0.9, "order" => 0.8,
      "class" => 0.6, "phylum" => 0.4, "kingdom" => 0.2 }

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
      @new_entry_ids = {}
      Array(options[:entry_ids]).each { |id| @new_entry_ids[id] = true }
      # TODO: Never used, currently; saving for later port work:
      @hierarchy_against = options[:against]
      @count = 0
      @all_hierarchies = options[:all_hierarchies]
      hiers = @browsable
      hiers = hiers.where(["id != ?", @hierarchy.id]) if @hierarchy.complete?
      @hierarchy_ids = hiers.pluck(:id)
      @per_page = Rails.configuration.solr_relationships_page_size.to_i
      @per_page = 1000 unless @per_page > 0
      @solr = SolrCore::HierarchyEntries.new
      @scores = {}
      @studied = {}
      @rank_conflicts = {}
    end

    def relate
      EOL.log("RELATE: #{@hierarchy.label} (#{@hierarchy.id})", prefix: "#")
      compare_entries
      add_curator_assertions
      delete_existing_relationships
      insert_relationships
      reindex_relationships
    end

    private

    def compare_entries
      EOL.log("Comparing entries for hierarchy ##{@hierarchy.id}")
      total = 0
      begin
        page ||= 0
        page += 1
        entries = get_page_from_solr(page)
        entries.each do |entry|
          begin
            compare_entry(study(entry)) if @new_entry_ids.has_key?(entry["id"])
          rescue => e
            EOL.log("Failed on entry ##{entry["id"]} (page #{page})")
            raise e
          end
        end
        total += entries.size
      end while entries.size > 0
      raise "Nothing compared!" if total == 0
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
      return "" if string.nil?
      string.gsub(/\\/, "\\\\\\\\").gsub(/"/, "\\\"")
    end

    def study(entry)
      if @studied.has_key?(entry["id"])
        EOL.log("Re-using studied entry #{entry["id"]}")
        return @studied[entry["id"]]
      end
      # April 2016: we decided that missing a scientific name (which is due to
      # non-ansi characters in the name) was insufficient cause to ignore it
      # entirely; match instead on the canonical form, which is clean.
      if entry["name"].blank?
        entry["name"] = entry["canonical_form"]
      end
      entry["rank_id"] ||= 0
      entry["kingdom_down"] = entry["kingdom"].try(:downcase)
      entry["quoted_canonical"] = metaquote(entry["canonical_form"])
      entry["quoted_name"] = metaquote(entry["name"])
      entry["is_virus"] = virus?(entry)
      entry["synonymy"] = synonymy_of(entry)
      @studied[entry["id"]] = entry
      entry
    end

    def virus?(entry)
      return true if entry["kingdom_down"] &&
        (entry["kingdom_down"] == "virus" || entry["kingdom_down"] == "viruses")
      return entry["quoted_canonical"].size >= 5 &&
        entry["quoted_canonical"][-5..-1] == "virus"
    end

    def synonymy_of(entry)
      if GOOD_SYNONYMY_HIERARCHY_IDS[entry["hierarchy_id"]] && entry["synonym"]
        entry["synonym"]
      else
        []
      end
    end

    # TODO: cleanup. :|
    def compare_entry(entry)
      matches = []
      # PHP TODO: "what about subgenera?"
      search_canonical = ""
      # TODO: store surrogate flag... somewhere. Store virus value there too
      if ! Name.is_surrogate_or_hybrid?(entry["quoted_name"]) &&
        ! entry["is_virus"] &&
        ! entry["canonical_form"].blank?
        search_canonical = entry["quoted_canonical"]
      end
      query_or_clause = []
      query_or_clause << "canonical_form_string:\"#{search_canonical}\"" unless
        search_canonical.blank?
      query_or_clause << "name:\"#{entry["quoted_name"]}\""
      # TODO: should we add this? The PHP code had NO WAY of getting to this:
      if (false)
        query_or_clause << "synonym_canonical:\"#{search_canonical}\""
      end
      query = "(#{query_or_clause.join(" OR ")})"
      query += hierarchy_clause
      # TODO: make rows variable configurable
      response = @solr.select(query, rows: 500)
      # NOTE: this was WAAAAAY too hard on Solr, we needed to gate it:
      sleep(0.3)
      rhead = response["responseHeader"]
      if rhead["QTime"] && rhead["QTime"].to_i > 200
        EOL.log("compare query: #{query}", prefix: ".")
        EOL.log("compare request took #{rhead["QTime"]}ms", prefix: ".")
      end
      matching_entries_from_solr = response["response"]["docs"]
      matching_entries_from_solr.each do |matching_entry|
        compare_entries_from_solr(entry, study(matching_entry))
      end
    end

    def compare_entries_from_solr(entry, matching_entry)
      score = score_comparison(entry, matching_entry)
      if score
        store_score(entry["id"], matching_entry["id"], score)
        store_score(matching_entry["id"], entry["id"], score)
      end
    end

    def hierarchy_clause
      @hierarchy_clause ||= if @hierarchy_against
        # TODO: Never used, currently; saving for later port work:
        " AND hierarchy_id:#{@hierarchy_against.id}"
      elsif @all_hierarchies
        # Complete hierarchies are not compared with themselves. Other (e.g.:
        # Flickr, which can have multiple occurrences of the "same" concept in
        # it) _do_ need to be compared with themselves.
        clause = " NOT hierarchy_id:#{@hierarchy.id}" if @hierarchy.complete?
        # PHP: "don't relate NCBI to itself"
        # TODO: This should NOT be hard-coded:
        clause += " NOT hierarchy_id:759" if @hierarchy.id == 1172
        clause += " NOT hierarchy_id:1172" if @hierarchy.id == 759
        clause
      else
        " AND (#{@hierarchy_ids.map { |id| "hierarchy_id:#{id}" }.join(" OR ")})"
      end
    end

    def score_comparison(from_entry, to_entry)
      return nil if from_entry["id"] == to_entry["id"]
      return nil if from_entry["name"].blank? || to_entry["name"].blank?
      return nil if @hierarchy.complete? &&
        from_entry["hierarchy_id"] == @hierarchy.id &&
        to_entry["hierarchy_id"] == @hierarchy.id
      return nil if
        rank_ids_conflict?(from_entry["rank_id"], to_entry["rank_id"])
      # PHP: "viruses are a pain and will not match properly right now"
      return(nil) if from_entry["is_virus"] || to_entry["is_virus"]
      is_synonym = false
      # nil, 0.5 (canonical), or 1 (scientific)... TODO: Symbols.
      name_score = compare_names(from_entry, to_entry)
      # If it's not a complete match, check for synonyms:
      if name_score.nil? || name_score == 0
        # 0 (none), 0.5 (canon), or 1 (sci):
        name_score = compare_synonyms(from_entry, to_entry)
        is_synonym = name_score > 0
      end
      total_score = if name_score.nil? || name_score == 0
        0
      else
        ancestry_score = compare_ancestries(from_entry, to_entry)
        if ancestry_score.nil?
          # One of the ancestries was totally empty:
          name_score * 0.5
        elsif ancestry_score > 0
          # Ancestry was reasonable match:
          name_score * ancestry_score
        else
          # Bad match:
          0
        end
      end
      # DO NOT SCORE ZEROES:
      total_score <= 0 ? nil : { score: total_score, synonym: is_synonym }
    end

    def rank_ids_conflict?(rid1, rid2)
      (low, high) = [rid1, rid2].sort
      key = "#{low}v#{high}"
      return @rank_conflicts[key] if @rank_conflicts.has_key?(key)
      @rank_conflicts[key] = if @rank_groups.has_key?(rid1) &&
                                @rank_groups.has_key?(rid2)
        @rank_groups[rid1] != @rank_groups[rid2]
      else
        rid1 && rid1 != 0 && rid2 && rid2 != 0 && rid1 != rid2
      end
    end

    def compare_names(from_entry, to_entry)
      return 1 if from_entry["name"] == to_entry["name"]
      return 0.5 if from_entry["canonical_form"] && to_entry["canonical_form"] &&
        from_entry["canonical_form"] == to_entry["canonical_form"]
      return nil
    end

    def compare_synonyms(from_entry, to_entry)
      if to_entry["synonymy"].include?(from_entry["name"]) ||
        from_entry["synonymy"].include?(to_entry["name"])
        1
      elsif to_entry["synonymy"].include?(from_entry["canonical_form"]) ||
        from_entry["synonymy"].include?(to_entry["canonical_form"])
        0.5
      else
        0
      end
    end

    # "check each rank in order of priority and return the respective weight on
    # match"
    def compare_ancestries(from_entry, to_entry)
      ancestry = study_ancestry(from_entry, to_entry)
      return nil if ancestry[:empty]
      # Never ever match bad kingdoms:
      return 0 if ancestry[:bad_kingdom]
      if ancestry[:match]["kingdom"]
        if ancestry[:match].size > 1
          # We matched on Kingdom AND something else, which is great!
          return 1
        else
          # We *only* had kingdoms to work with... If neither entry has other
          # ranks at all, return the score based on kingdom only:
          return RANK_WEIGHTS["kingdom"] unless ancestry[:both_have_non_kingdom]
          # So here we've got at least one entry with other ranks *available*,
          # but they didn't match. This is only okay if both entries have a rank
          # that allows this:
          return 0 unless
            allowed_to_match_at_kingdom_only?(from_entry, to_entry)
          # If we haven't returned, then we're looking at a pair of higher-level
          # entries that matched only at kingdom (which is fine)
        end
      end
      return ancestry[:best_score]
    end

    def study_ancestry(from_entry, to_entry)
      # TODO: This is really a struct.
      ancestry = { match: {}, only_from: {}, only_to: {}, contradict: {},
        both_empty: {}, best_score: 0 }
      RANK_WEIGHTS.sort_by { |k,v| - v }.each do |rank, weight|
        if from_entry[rank] && to_entry[rank]
          unless rank == "kingdom"
            ancestry[:from_has_non_kingdom] = true
            ancestry[:to_has_non_kingdom] = true
          end
          if from_entry[rank] == to_entry[rank] # MATCH!
            ancestry[:match][rank] = true
            ancestry[:best_score] = weight if weight > ancestry[:best_score]
          else # CONTRADICTION!
            ancestry[:contradict][rank] = true
            if rank == "kingdom"
              # If either of them is Animalia, absolutely DO NOT MATCH!
              if from_entry[rank].downcase == "animalia" ||
                 to_entry[rank].downcase == "animalia"
                ancestry[:bad_kingdom] = true
              end
            end
          end
        elsif from_entry[rank]
          ancestry[:only_from][rank] = true
          ancestry[:from_has_non_kingdom] = true unless rank == "kingdom"
        elsif to_entry[rank]
          ancestry[:only_to][rank] = true
          ancestry[:to_has_non_kingdom] = true unless rank == "kingdom"
        end
      end
      ancestry[:empty] = ancestry[:match].empty? &&
        ancestry[:only_from].empty? &&
        ancestry[:only_to].empty? &&
        ancestry[:contradict].empty?
      ancestry[:both_have_non_kingdom] = ancestry[:to_has_non_kingdom] &&
        ancestry[:from_has_non_kingdom]
      return ancestry
    end

    def allowed_to_match_at_kingdom_only?(from_entry, to_entry)
      RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY[from_entry["rank_id"]] &&
        RANKS_ALLOWED_TO_MATCH_AT_KINGDOM_ONLY[to_entry["rank_id"]]
    end

    def store_score(from, to, score)
      type = score[:synonym] ? 'syn' : 'name'
      key = "#{from},#{to},'#{type}'"
      unless @scores.has_key?(key) && @scores[key] < score[:score]
        @scores[key] = score[:score]
      end
      size = @scores.size
      EOL.log("#{size} relationships...", prefix: ".") if size % 1_000 == 0
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
      relationships = @scores.keys.map { |key| "#{key},#{@scores[key]}" }
      EOL::Db.bulk_insert(HierarchyEntryRelationship,
        [:hierarchy_entry_id_1, :hierarchy_entry_id_2, :relationship, :score],
        relationships)
      relationships.size
    end

    # NOTE: PHP did this before swapping the tmp tables (because it never did,
    # perhaps), so the code _there_ actually reads from the tmp table. That
    # didn't make sense to me (too convoluted), so I've moved it.
    def reindex_relationships
      EOL.log_call
      SolrCore::HierarchyEntryRelationships.
        reindex_entries_in_hierarchy(@hierarchy, @new_entry_ids.keys)
    end
  end
end
