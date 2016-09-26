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
      EOL.log("Looking up relationships")
      relationships = Set.new
      # This is a little dizzying, and in reality, we reload some entries... but
      # this is actaully most efficient without tons of custom code:
      entries = HierarchyEntry.includes(
        relationships_from: [:to_hierarchy_entry],
        relationships_to: [:from_hierarchy_entry]
      ).where(id: entry_ids)
      index = 0
      total = (entries.size / 1000.0).ceil
      entries.find_in_batches(batch_size: 1000) do |batch|
        index += 1
        EOL.log("batch #{index}/#{total}", prefix: "@") if index > 1
        batch.each do |entry|
          relationships += entry.relationships_from.map(&:to_hash)
          relationships += entry.relationships_to.map(&:to_hash)
        end
      end
      relationships.delete_if { |r| r.blank? }
      count = 0
      total = relationships.size
      entry_ids.in_groups_of(500, false) do |group|
        id = group.join(' OR ')
        delete(["hierarchy_entry_id_1:(#{id})", "hierarchy_entry_id_2:(#{id})"])
      end
      relationships.to_a.in_groups_of(5000, false) do |group|
        count += group.size
        EOL.log("Solr reindex: #{count}/#{total}")
        add_items(group)
      end
    end
  end
end
