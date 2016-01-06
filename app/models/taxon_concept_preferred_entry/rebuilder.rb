class TaxonConceptPreferredEntry
  class Rebuilder

    attr_reader :all_entries, :curated_entries, :best_entries

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
      @all_entries = {}
      @curated_entries = {}
      @best_entries = {}
    end

    def rebuild
      EOL.log_call
      EOL::Db.with_tmp_tables([TaxonConceptPreferredEntry]) do
        get_all_entries
        get_curated_entries
        get_best_entries
        insert_best_entries
        EOL::Db.swap_tmp_table(TaxonConceptPreferredEntry)
      end
    end

    def get_all_entries
      EOL.log_call
      count = 0
      HierarchyEntry.published.includes(:taxon_concept, :hierarchy).
        find_each do |entry|
        count += 1
        EOL.log(".. entry #{count}") if count % 10_000 == 0
        @all_entries[entry.taxon_concept_id] ||= []
        @all_entries[entry.taxon_concept_id] << {
          hierarchy_entry_id: entry.id,
          vetted_view_order: Vetted.weight[entry.vetted_id],
          browsable: entry.hierarchy.browsable,
          hierarchy_sort_order: hierarchy_sort_order(entry.hierarchy.label)
        }
      end
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
      @all_entries.each do |taxon_concept_id, concept_entries|
        @best_entries[taxon_concept_id] = concept_entries.
          sort_by { |entry| entry_sort(entry) }.
          first[:hierarchy_entry_id]
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
      [ entry[:vetted_view_order],
        0 - entry[:browsable],
        entry[:hierarchy_sort_order],
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
