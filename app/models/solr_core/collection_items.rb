class SolrCore
  class CollectionItems < SolrCore::Base
    CORE_NAME = "collection_items"

    def delete_items(items)
      items = Array(items)
      begin
        @connection.delete_by_query(items.map do |item|
          "object_type:#{item.collected_item_type} AND "\
            "object_id:#{item.collected_item_id}"
        end)
      rescue RSolr::Error::Http => e
        # Doesn't *really* matter, move along.
      end
    end

    def initialize
      connect(CORE_NAME)
    end
  end
end
