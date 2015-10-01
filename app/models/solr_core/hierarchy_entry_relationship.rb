module SolrCore
  class HierarchyEntryRelationship < SolrCore::Base
    # Yes, it's really singular. I didn't design it:
    CORE_NAME = "hierarchy_entry_relationship"

    def initialize
      connect(CORE_NAME)
    end
  end
end
