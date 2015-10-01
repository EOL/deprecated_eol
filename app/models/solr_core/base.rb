module SolrCore
  class Base
    attr_reader :connection

    def connect(name)
      @core = name
      @connection = RSolr.connect(url: "#{$SOLR_SERVER}#{name}")
    end

    def optimize
      EOL.log_call
      response = @connection.update(:data => '<optimize/>')
      EOL.log("Optimizing #{@core} Solr core done: #{response.to_json}",
        prefix: '.')
    end
  end
end
