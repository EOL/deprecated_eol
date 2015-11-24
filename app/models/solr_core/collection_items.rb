class SolrCore
  class CollectionItems < SolrCore::Base
    CORE_NAME = "collection_items"

    def initialize
      connect(CORE_NAME)
    end
  end
end
