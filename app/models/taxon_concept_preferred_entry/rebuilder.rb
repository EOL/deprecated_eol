class TaxonConceptPreferredEntry
  class Rebuilder

    attr_reader :entries, :curated_entries, :best_entries

    # TODO - THIS SHOULD NOT BE HARD-CODED! (╯°□°)╯︵ ┻━┻
    # NOTE: this is ALSO hard-coded in Hierarchy.sort_order!! Same? TODO
    HIERARCHY_MATCH_PRIORITY = [
      /^Species 2000 & ITIS Catalogue of Life/i,
      /^Integrated Taxonomic Information System/i,
      "Avibase - IOC World Bird Names (2011)",
      "WORMS Species Information (Marine Species)",
      "FishBase (Fish Species)",
      "IUCN Red List (Species Assessed for Global Conservation)",
      "Index Fungorum",
      "Paleobiology Database"
    ]

    def initialize
      @entries = {}
      @hierarchies = {}
      @curated_entries = {}
      @best_entries = {}
    end

    def rebuild
      EOL.log_call
      EOL::Db.with_tmp_tables([TaxonConceptPreferredEntry]) do
        get_entries
        get_hierarchies
        get_curated_entries
        get_best_entries
        insert_best_entries
        EOL::Db.swap_tmp_table(TaxonConceptPreferredEntry)
      end
    end

    def get_entries
      EOL.log_call
      count = 0
      last = HierarchyEntry.maximum(:id)
      batch = 10_000
      low = HierarchyEntry.published.first.id
      fields = [:id, :taxon_concept_id, :hierarchy_id, :vetted_id]
      dat = []
      begin
        dat = EOL.pluck_fields(fields,
          HierarchyEntry.published.
          where(["id > ? AND id < ?", low, low + batch]))
        dat.each do |row|
          h = EOL.unpluck_ids(fields, row)
          concept_id = h.delete(:taxon_concept_id)
          @entries[concept_id] ||= []
          @entries[concept_id] << h
        end
        low += batch + 1
      end until low > last
    end

    def get_hierarchies
      EOL.log_call
      count = 0
      last = Hierarchy.maximum(:id)
      batch = 10_000
      low = Hierarchy.first.id
      fields = [:id, :browsable, :label]
      dat = []
      begin
        dat = EOL.pluck_fields(fields,
          Hierarchy.where(["id > ? AND id < ?", low, low + batch]))
        dat.compact.each do |row|
          (id, browsable, label) = row.split(",", 3)
          @hierarchies[id] = { browsable: browsable,
            sort: hierarchy_sort_order(label) }
        end
        low += batch + 1
      end until low > last
    end

    def get_curated_entries
      EOL.log_call
      CuratedTaxonConceptPreferredEntry.includes(:hierarchy_entry).
        joins(:hierarchy_entry).
        where(hierarchy_entries: { published: true,
          visibility_id: Visibility.get_visible.id }).
        find_each do |pref|
        # NOTE: there is only one preferred entry per concept (for now)
        @curated_entries[pref.taxon_concept_id] = pref.hierarchy_entry_id
      end
    end

    def get_best_entries
      EOL.log_call
      @entries.each do |taxon_concept_id, concept_entries|
        @best_entries[taxon_concept_id] = concept_entries.
          sort_by { |entry| entry_sort(entry) }.
          first[:id]
      end
      @curated_entries.each do |taxon_concept_id, hierarchy_entry_id|
        # NOTE this trumps any value that may have already been in there...
        @best_entries[taxon_concept_id] = hierarchy_entry_id if
          # PL: "its possible to have a saved curated entry for a concept that
          # no longer exits so make sure we are setting the preferred value for
          # a concept that we know about"
          @best_entries[taxon_concept_id]
      end
    end

    def insert_best_entries
      EOL.log_call
      values = []
      @best_entries.each do |taxon_concept_id, hierarchy_entry_id|
        values << "#{taxon_concept_id}, #{hierarchy_entry_id}"
      end
      EOL::Db.bulk_insert(TaxonConceptPreferredEntry,
        [:taxon_concept_id, :hierarchy_entry_id],
        values, tmp: true)
    end

    def entry_sort(entry)
      hierarchy = @hierarchies[entry[:hierarchy_id]] ||
        { browsable: 0, sort: 999}
      [ Vetted.weight[entry[:vetted_id]],
        0 - hierarchy[:browsable],
        hierarchy[:sort],
        entry[:hierarchy_entry_id] ]
    end

    def hierarchy_sort_order(label)
      HIERARCHY_MATCH_PRIORITY.each_with_index do |match, weight|
        if match.is_a?(Regexp) ? label =~ match : label == match
          return weight + 1
        end
        return 999
      end
    end
  end
end
