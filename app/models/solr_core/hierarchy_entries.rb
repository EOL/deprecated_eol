class SolrCore
  class HierarchyEntries < SolrCore::Base
    CORE_NAME = "hierarchy_entries"

    # TODO: Absolutely ABSURD that this is not in the rank table. We're using
    # "groups", without giving each group an appropriate label. We should do
    # that.
    @solr_rank_map = {
      'kingdom' =>  :kingdom,
      'regn.' => :kingdom,
      'phylum' => :phylum,
      'phyl.' => :phylum,
      'class' => :class,
      'cl.' => :class,
      'order' => :order,
      'ord.' => :order,
      'family' => :family,
      'fam.' => :family,
      'f.' => :family,
      'genus' => :genus,
      'gen.' => :genus,
      'species' => :species,
      'sp.' => :species
    }

    attr_reader :ancestors

    def self.reindex_hierarchy(hierarchy)
      solr = self.new
      solr.reindex_hierarchy(hierarchy)
    end

    def initialize
      connect(CORE_NAME)
      @ancestors = {}
    end

    def reindex_hierarchy(hierarchy)
      EOL.log_call
      # def
      objects = Set.new
      # This  query takes 10min in production for 533_548 entries:
      ancestry = hierarchy.ancestry_set
      entry_ancestors = {}
      ancestry.each do |pair|
        (entry, ancestor) = pair.split(",")
        entry_ancestors[entry.to_i] ||= []
        entry_ancestors[entry.to_i] << ancestor.to_i
      end
      entries = []
      all_ids = Set.new(ancestry.map { |s| s.split(",")[0] })
      all_ids.to_a.in_groups_of(10_000, false) do |ids|
        entries += HierarchyEntry.where(id: ids).
          includes(synonyms: { name: :canonical_form}, name: :canonical_form)
      end
      entries.each do |entry|
        entry.ancestor_names = {}
        entry_ancestors[entry.id].each do |ancestor|
          if rank = Rank.label(ancestor.rank_id)
            entry.ancestor_names.merge!(rank => ancestor.name.string)
          end
        end
      end
      reindex_items(entries)
    end
  end
end
