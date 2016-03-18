class TaxonConcept
  module Cleanup
    def unpublish_and_hide_by_entry_ids(entry_ids)
      ids = HierarchyEntry.where(id: Array(entry_ids)).pluck(:taxon_concept_id)
      unpublish_concepts_with_no_published_entries(ids)
      untrust_concepts_with_no_visible_trusted_entries(ids)
    end

    def unpublish_concepts_with_no_published_entries(ids)
      TaxonConcept.published.
        # TODO: clean up with ARel (yes, LEFT joins are hard, but still:)
        joins("LEFT JOIN hierarchy_entries "\
          "ON (taxon_concepts.id = hierarchy_entries.taxon_concept_id "\
          "AND hierarchy_entries.published = 1)").
        where(["hierarchy_entries.id IS NULL AND taxon_concepts.id IN (?)", ids]).
        update_all(["taxon_concepts.published = ?", false])
    end

    def untrust_concepts_with_no_visible_trusted_entries(ids)
      TaxonConcept.published.trusted.unsuperceded.
        # TODO: clean up with ARel (yes, LEFT joins are hard, but still:)
        joins("LEFT JOIN hierarchy_entries "\
          "ON (taxon_concepts.id = hierarchy_entries.taxon_concept_id AND "\
          "hierarchy_entries.visibility_id = #{Visibility.get_visible.id} AND "\
          "hierarchy_entries.vetted_id = #{Vetted.trusted.id})").
        where(["hierarchy_entries.id IS NULL AND taxon_concepts.id IN (?)", ids]).
        update_all(["taxon_concepts.vetted_id = ?", Vetted.unknown.id])
    end

    # NOTE: This is currently unused and is only here for manual cleanup.
    def publish_concepts_with_published_entries
      TaxonConcept.unpublished.
        joins(:hierarchy_entries).
        where(hierarchy_entries: { published: true,
          visibility_id: Visibility.get_visible.id }).
        update_all(["taxon_concepts.published = ?", true])
    end

    # NOTE: This is currently unused and is only here for manual cleanup.
    def trust_concepts_with_visible_trusted_entries(hierarchy_ids = [])
      hierarchy_ids = Array(hierarchy_ids)
      TaxonConcept.trusted.
        joins(:hierarchy_entries).
        where(["hierarchy_entries.visibility_id = ? AND "\
          "hierarchy_entries.vetted_id = ? " + hierarchy_ids.empty? ? '' :
          "AND hierarchy_entries.hierarchy_id IN (?)",
          Visibility.get_visible.id, Vetted.trusted.id, hierarchy_ids]).
        update_all(["taxon_concepts.vetted_id = ?", Vetted.trusted.id])
    end
  end
end
