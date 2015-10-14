module SolrCore
  class HierarchyEntryRelationships < SolrCore::Base
    # Yes, it's really singular. I didn't design it:
    CORE_NAME = "hierarchy_entry_relationship"

    def self.reindex_entries_in_hierarchy(hierarchy, entry_ids)
      solr = self.new
      solr.reindex_entries_in_hierarchy(hierarchy, entry_ids)
    end

    def initialize
      connect(CORE_NAME)
    end

    def reindex_entries_in_hierarchy(hierarchy, entry_ids)
      EOL.log_call
      entry_ids.in_groups_of(500, false) do |group|
        id = group.join(' OR ')
        delete(["hierarchy_entry_id_1:(#{id})", "hierarchy_entry_id_2:(#{id})"])
      end
      EOL.log("Looking up relationships")
      relationships = []
      # Whoa. PHP query... sigh:
      HierarchyEntryRelationship.
        select("he1.id id1, he1.taxon_concept_id taxon_concept_id1, "\
          "he1.hierarchy_id hierarchy_id1, he1.visibility_id visibility_id1, "\
          "he2.id id2, he2.taxon_concept_id taxon_concept_id2, "\
          "he2.hierarchy_id hierarchy_id2, he2.visibility_id visibility_id2, "\
          "he1.taxon_concept_id = he2.taxon_concept_id same_concept, "\
          "hierarchy_entry_relationships.relationship, "\
          "hierarchy_entry_relationships.score").
        joins("JOIN hierarchy_entries he1 ON "\
          "(hierarchy_entry_relationships.hierarchy_entry_id_1 = he1.id) JOIN "\
          "hierarchy_entries he2 ON "\
          "(hierarchy_entry_relationships.hierarchy_entry_id_2 = he2.id)").
        find_each do |relationship|
        relationships << relationship.to_hash # TODO
      end
      # TODO: I am not 100% that this will work with a really big array:
      add_items(relationships)
    end
  end
end
