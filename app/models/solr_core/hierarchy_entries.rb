module SolrCore
  class HierarchyEntries < SolrCore::Base
    CORE_NAME = "hierarchy_entries"

    def initialize
      connect(CORE_NAME)
    end
  end
end
