module EOL
  module Sparql
    class FourStoreEndpoint < Endpoint

      attr_accessor :action_uri

      def initialize(options={})
        self.action_uri = options[:action_uri]
        super(options)
      end

      # 4store needs its updates posted to /update/ as form data
      # see http://4store.org/trac/wiki/SparqlServer
      def sparql_update(query)
        uri = URI(action_uri + 'update/')
        request = Net::HTTP::Post.new(uri.request_uri)
        request.set_form_data({ "update" => query })
        request.content_type = 'application/x-www-form-urlencoded'

        response = Net::HTTP.start(uri.host, uri.port) do |http|
          http.open_timeout = 30
          http.read_timeout = 240
          http.request(request)
        end
      end

      # 4store insert data is getting posted to /data/ in Turtle format
      # see http://4store.org/trac/wiki/SparqlServer
      def insert_data(options={})
        unless options[:data].blank?
          query = namespaces.collect{ |key,value| "@prefix #{key}: <#{value}>"}.join(" .\n") + " . \n"
          query += options[:data].join(" .\n") + " . \n"
          uri = URI(action_uri + 'data/')
          request = Net::HTTP::Post.new(uri.request_uri)
          request.set_form_data({ "data" => query, "graph" => options[:graph_name], "mime-type" => "application/x-turtle" })
          request.content_type = 'application/x-www-form-urlencoded'

          response = Net::HTTP.start(uri.host, uri.port) do |http|
            http.open_timeout = 30
            http.read_timeout = 240
            http.request(request)
          end
          pp response
          if response.code.to_i != 201 && response.code.to_i != 200
            debugger
            puts "..."
          end
        end
      end

      # # This is an alternative way to delete 4store graphs
      def delete_graph(graph_name)
        uri = URI(action_uri)
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Delete.new("/data/?graph=" + graph_name)
          http.request(request)
        end
        puts "Deleted graph #{graph_name}..."
      end

    end
  end
end
