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
      relationships = Set.new
      # NOTE: YOU **CANNOT** USE #find_each (or #find_in_batches) HERE. The
      # scope being applied seems to screw it up; you will *always* get 1000
      # results (assuming you have more than that to scan through) in
      # relationships if you try to use it. Don't.
      HierarchyEntryRelationship.by_hierarchy_for_hashes(hierarchy.id).
        each do |relationship|
        relationships << relationship.to_hash
      end
      relationships.delete_if { |r| r.blank? }
      count = 0
      total = relationships.size
      relationships.to_a.in_groups_of(5000, false) do |group|
        count += group.size
        EOL.log("Solr reindex: #{count}/#{total}")
        add_items(group)
      end
    end
  end
end
