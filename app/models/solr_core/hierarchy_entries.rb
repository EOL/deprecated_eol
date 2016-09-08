class SolrCore
  class HierarchyEntries < SolrCore::Base
    CORE_NAME = "hierarchy_entries"

    attr_reader :ancestors

    def self.reindex_hierarchy(hierarchy, options = {})
      solr = self.new
      solr.reindex_hierarchy(hierarchy, options)
    end

    def initialize
      connect(CORE_NAME)
      @ancestors = {}
      @ids = []
      @all_ids = Set.new
    end

    def reindex_hierarchy(hierarchy, options = {})
      EOL.log_call
      @ids = Array(options[:ids])
      ancestry = EOL.wait_for_results { hierarchy.ancestry_set }
      entry_ancestors = build_entry_ancestors(ancestry)
      entries = build_entries
      add_ancestry(entries, entry_ancestors)
      EOL.log("Found #{entries.size} entries")
      raise "PROBLEM: no entries found!" if entries.size == 0
      if @ids.empty?
        delete("hierarchy_id:#{hierarchy.id}")
      end
      reindex_items(entries)
    end

    def build_entry_ancestors(ancestry)
      entry_ancestors = {}
      EOL.log("Given #{@ids.size} IDs to index.") unless @ids.empty?
      ancestry.group_by(&:hierarchy_entry_id).each do |eid, ancestors|
        next unless @ids.empty? || @ids.include?(ancestor.hierarchy_entry_id)
        a_ids = ancestors.map(&:ancestor_id)
        entry_ancestors[eid] = a_ids
        @all_ids << eid
        @all_ids += a_ids
      end
      entry_ancestors
    end

    def build_entries
      entries = []
      @all_ids.to_a.in_groups_of(10_000, false) do |ids|
        entries += HierarchyEntry.where(id: ids).
          includes(synonyms: { name: :canonical_form}, name: :canonical_form)
      end
      # We can't do anything with it, if the canonical form is blank!
      entries.delete_if { |e| e.name.canonical_form.nil? }
    end

    def add_ancestry(entries, entry_ancestors)
      EOL.log("Adding ancestry (#{entries.size} entries)")
      # This can take a few seconds but vastly speeds up the rest:
      indexed_entries = {}
      entries.each { |entry| indexed_entries[entry.id] = entry }
      entries.each_with_index do |entry, index|
        entry.ancestor_names = {}
        if ancestors = entry_ancestors[entry.id]
          ancestors.each do |ancestor_id|
            ancestor = indexed_entries[ancestor_id]
            if ancestor && ancestor.rank_id && rank = Rank.label(ancestor.rank_id)
              entry.ancestor_names.merge!(rank => ancestor.name.string)
            end
          end
        end
      end
    end
  end
end
