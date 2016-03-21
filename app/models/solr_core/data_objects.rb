class SolrCore
  class DataObjects < SolrCore::Base
    CORE_NAME = "data_objects"

    def initialize
      connect(CORE_NAME)
    end

    def reindex_hashes(items)
      items = Array(items)
      EOL.log("SolrCore::DataObjets#reindex_hashes (#{items.size} items)", prefix: '.')
      delete(items.map { |i| "data_object_id:#{i[:data_object_id]}" })
      @connection.add(items)
      @connection.commit
    end
  end
end
