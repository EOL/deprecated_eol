class TaxonConceptPreferredEntry
  class Rebuilder

    attr_reader :all_entries, :curated_entries, :best_entries

    # TODO - THIS SHOULD NOT BE HARD-CODED! (╯°□°)╯︵ ┻━┻
    # NOTE: this is ALSO hard-coded in Hierarchy.sort_order!! Same? TODO
    @hierarchy_match_priority = [
      /^Species 2000 & ITIS Catalogue of Life/i,
      /^Integrated Taxonomic Information System/i,
      "Avibase - IOC World Bird Names (2011)",
      "WORMS Species Information (Marine Species)",
      "FishBase (Fish Species)",
      # TODO - remove the backslash. I'm just getting around an Atom bug.
      "IUCN \Red List (Species Assessed for Global Conservation)",
      "Index Fungorum",
      "Paleobiology Database"
    ]

    def self.hierarchy_sort_order(label)
      @hierarchy_match_priority.each_with_index do |match, weight|
        if match.is_a?(Regexp) ? label =~ match : label == match
          return weight + 1
        end
        return 999
      end
    end

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
      # TODO - this was just copied from PHP. Improve.
      TaxonConcept.select("taxon_concepts.id id, "\
        "he.id hierarchy_entry_id, "\
        "he.visibility_id, v.view_order vetted_view_order, "\
        "h.id hierarchy_id, h.browsable, h.label").
        joins("STRAIGHT_JOIN hierarchy_entries he "\
          "ON (taxon_concepts.id = he.taxon_concept_id) "\
          "STRAIGHT_JOIN hierarchies h ON (he.hierarchy_id = h.id) "\
          "STRAIGHT_JOIN vetted v ON (he.vetted_id = v.id)").
        where("he.published = 1").
        find_each do |taxon|
        EOL.log(".. taxon #{taxon.id}")
        @all_entries[taxon.id] ||= []
        @all_entries[taxon.id] << {
          hierarchy_entry_id: taxon["hierarchy_entry_id"].to_i,
          vetted_view_order: taxon["vetted_view_order"].to_i,
          browsable: taxon["browsable"].to_i,
          hierarchy_sort_order: TaxonConceptPreferredEntry::Rebuilder.
            hierarchy_sort_order(taxon["label"])
        }
      end
    end

    def get_curated_entries
      EOL.log_call
      # TODO - this could be done with a group by query, I think. Maybe not.
      CuratedTaxonConceptPreferredEntry.
        select("curated_taxon_concept_preferred_entries.taxon_concept_id, "\
          "curated_taxon_concept_preferred_entries.hierarchy_entry_id").
        joins("JOIN hierarchy_entries").
        where(hierarchy_entries: { published: true,
          visibility_id: Visibility.get_visible.id }).
        find_each do |ctcpe|
        # NOTE: there is only one preferred hierarchy (for now)
        @curated_entries[ctcpe["taxon_concept_id"]] =
          ctcpe["hierarchy_entry_id"]
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
  end
end
