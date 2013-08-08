module EOL
  module Sparql
    class Client

      attr_accessor :endpoint_uri, :namespaces, :username, :password, :sparql_client

      def initialize(options={})
        @endpoint_uri = options[:endpoint_uri]
        @username = options[:username]
        @password = options[:password]
        @namespaces = EOL::Sparql::NAMESPACES
        @sparql_client = SPARQL::Client.new(endpoint_uri)
      end

      # You must implement this in your child class.
      def insert_data(options={})
        raise NotImplementedError
      end

      def delete_data(options = {})
        if options[:graph_name] && options[:data]
          update("DELETE DATA FROM <#{options[:graph_name]}> { #{options[:data]} }")
        end
      end

      def delete_uri(options)
        if options[:graph_name] && options[:uri]
          sparql_client.query("DELETE FROM <#{options[:graph_name]}> { <#{options[:uri]}> ?p ?o } WHERE { <#{options[:uri]}> ?p ?o }")
        end
      end

      def update(query)
        sparql_client.query("#{namespaces_prefixes} #{query}")
      end

      def delete_graph(graph_name)
        return unless graph_name
        delete_graph_via_sparql_update(graph_name)
      end

      # NOTE: if you get an error: Invalid port number: "8890/DAV/xx/yy", then go to:
      # http://localhost:8890/ => LinkedData => Graphs and check to see if there is a graph named
      # http://localhost:8890%2FDAV%2Fxx%2Fyy . If so, delete it and try again
      def query(query, options = {})
        results = []
        begin
          sparql_client.query("#{options[:prefix]} #{namespaces_prefixes} #{query}").each_solution { |s| results << s.to_hash }
        rescue ArgumentError => e
          # NOTE - this catch is caused by going through the demo for setting up the DAV user/directory. You've got to manually delete that
          # later!
          if e.message =~ /Invalid port number/
            puts "We found a graph that cannot be removed programmatically."
            puts "Please go to http://localhost:8890/ => Conductor => LinkedData => Graphs and check to see"
            puts "if there is a graph named http://localhost:8890%2FDAV%2Fxx%2Fyy ...if so, delete it and"
            puts "try again. Sorry!"
          end
          raise e
        end
        results
      end

    private

      def delete_graph_via_sparql_update(graph_name)
        return unless graph_name
        update("CLEAR GRAPH <#{graph_name}>")
        update("DROP SILENT GRAPH <#{graph_name}>")
      end

      def namespaces_prefixes
        namespaces.collect{ |key,value| "PREFIX #{key}: <#{value}>"}.join(" ")
      end

    end
  end
end
