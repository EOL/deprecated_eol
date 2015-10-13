module SolrCore
  class Base
    attr_reader :connection

    def self.delete_by_ids(ids)
      solr = self.new
      solr.delete_by_ids(ids)
    end

    def self.optimize
      solr = self.new
      solr.optimize
    end

    def self.reindex_items(items)
      solr = self.new
      solr.reindex_items(items)
    end

    def connect(name)
      return if @connection
      @core = name
      @connection = RSolr.connect(url: "#{$SOLR_SERVER}#{name}")
    end

    def delete_by_ids(ids)
      ids = Array(ids)
      # NOTE: yes, this call is singular (but can take an array)
      @connection.delete_by_id(ids)
    end

    def optimize
      EOL.log_call
      response = @connection.update(:data => '<optimize/>')
      EOL.log("Optimizing #{@core} Solr core done: #{response.to_json}",
        prefix: '.')
    end

    def reindex_items(items)
      items = Array(items)
      delete_by_ids(items.map(&:id))
      @connection.add(items.map(&:to_hash))
    end

    # NOTE: returns eval'ed ruby (a hash):
    def select(q, options = {})
      params = options.merge(q: q)
      connection.select(params: params)
    end
  end
end
