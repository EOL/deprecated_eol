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
  # Hierarchy#reindex_and_merge_ids and
  # HarvestEvent#relate_new_hierarchy_entries
  class Relator
    def self.relate(hierarchy, options = {})
      relator = self.new(hierarchy, options)
      relator.relate
    end

    def initialize(hierarchy, options = {})
      # We load this at runtime, so new ranks are read in:
      @hierarchy = hierarchy
      @browsable = Hierarchy.browsable
      @new_entry_ids = {}
      Array(options[:entry_ids]).each { |id| @new_entry_ids[id] = true }
      # TODO: Never used, currently; saving for later port work:
      @hierarchy_against = options[:against]
      @all_hierarchies = options[:all_hierarchies]
      hiers = @browsable
      hiers = hiers.where(["id != ?", @hierarchy.id]) if @hierarchy.complete?
      @hierarchy_ids = hiers.pluck(:id)
      @per_page = Rails.configuration.solr_relationships_page_size.to_i
      @per_page = 1000 unless @per_page > 0
      @solr = SolrCore::HierarchyEntries.new
      @scores = {}
      @similarity = Hierarchy::Similarity.new
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
            compare_entry(@similarity.study(entry)) if
              @new_entry_ids.has_key?(entry["id"])
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
      if rhead["QTime"] && rhead["QTime"].to_i > 250
        if rhead["q"] && ! rhead["q"].blank?
          EOL.log("relator query: #{rhead["q"]}", prefix: ".")
        else
          EOL.log("header: #{rhead.inspect}")
        end
        EOL.log("relator request took #{rhead["QTime"]}ms", prefix: ".")
      end
      if page == 1 && response["response"] && response["response"]["numFound"]
        EOL.log("Total of #{response["response"]["numFound"]} entries")
      end
      response["response"]["docs"]
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
        EOL.log("SLOW: #{query} took #{rhead["QTime"]}ms", prefix: "!")
      end
      matching_entries_from_solr = response["response"]["docs"]
      matching_entries_from_solr.each do |matching_entry|
        compare_entries_from_solr(entry, matching_entry)
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

    def compare_entries_from_solr(entry, matching_entry)
      score = @similarity.compare(entry, matching_entry,
        from_studied: true, complete: @hierarchy.complete?)
      if score.is_a?(Hash) && score[:score] && score[:score] > 0
        store_score(score)
      end
    end

    def store_score(score)
      type = score[:is_synonym] ? 'syn' : 'name'
      keys = ["#{score[:from]},#{score[:to]},'#{type}'",
              "#{score[:to]},#{score[:from]},'#{type}'"]
      keys.each do |key|
        unless @scores.has_key?(key) && @scores[key] < score[:score]
          @scores[key] = score[:score]
          size = @scores.size
          EOL.log("#{size} relationships...", prefix: ".") if size % 1_000 == 0
        end
      end
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
