class SolrCore
  class DataObjects < SolrCore::Base
    CORE_NAME = "data_objects"

    def initialize
      connect(CORE_NAME)
    end

    def reindex_hashes(items)
      EOL.log_call
      items = Array(items)
      EOL.log("(#{items.count} items)", prefix: '.')
      delete(items.map { |i| "data_object_id:#{i[:data_object_id]}" })
      @connection.add(items)
      @connection.commit
    end
  end
end
