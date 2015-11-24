class SolrCore
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
      HierarchyEntryRelationship.by_hierarchy_for_hashes(@hierarchy_id).
        find_each do |relationship|
        hash = relationship.to_hash
        # TODO: remove this!
        debugger unless hash.has_key?("visibility_id_1")
        relationships << hash unless hash.blank?
      end
      relationships.in_groups_of(5000, false) do |group|
        add_items(group)
      end
    end
  end
end
