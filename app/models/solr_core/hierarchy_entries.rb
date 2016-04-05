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
      entries = build_entries(ancestry)
      add_ancestry(entries, entry_ancestors)
      EOL.log("Found #{entries.size} entries")
      raise "PROBLEM: no entries found!" if entries.size == 0
      reindex_items(entries)
    end

    def build_entry_ancestors(ancestry)
      entry_ancestors = {}
      EOL.log("Given #{@ids.size} IDs to index.") if @ids
      ancestry.each do |pair|
        (entry, ancestor) = pair.split(",").map(&:to_i)
        next unless @ids.empty? || @ids.include?(entry)
        entry_ancestors[entry] ||= []
        entry_ancestors[entry] << ancestor
        @all_ids += [entry, ancestor]
      end
      entry_ancestors
    end

    def build_entries(ancestry)
      entries = []
      @all_ids.to_a.in_groups_of(10_000, false) do |ids|
        entries += HierarchyEntry.where(id: ids).
          includes(synonyms: { name: :canonical_form}, name: :canonical_form)
      end
      # We can't do anything with it, if the canonical form is blank!
      entries.delete_if { |e| e.name.canonical_form.nil? }
    end

    def add_ancestry(entries, entry_ancestors)
      entries.each do |entry|
        entry.ancestor_names = {}
        if entry_ancestors.has_key?(entry.id)
          entry_ancestors[entry.id].each do |ancestor_id|
            ancestor = entries.find { |e| e.id == ancestor_id }
            if ancestor && ancestor.rank_id && rank = Rank.label(ancestor.rank_id)
              entry.ancestor_names.merge!(rank => ancestor.name.string)
            end
          end
        end
      end
    end
  end
end
