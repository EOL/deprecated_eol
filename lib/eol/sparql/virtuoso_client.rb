# NOTE - this uses a Rails logger, so you can't use this library outside of Rails, for the moment.
module EOL
  module Sparql
    class VirtuosoClient < Client

      attr_accessor :upload_uri

      # NOTE - this is VERY DANGEROUS. Your gun, your foot.
      def self.drop_all_graphs
        all_graph_names.each do |result|
          graph_name = result[:graph].to_s
          if graph_name =~ /^http:\/\/eol\.org\//
            delete_graph(graph_name)
          end
        end
      end

      def self.all_graph_names
        EOL::Sparql.connection.query(
          "SELECT ?graph WHERE { GRAPH ?graph { ?s ?p ?o } } GROUP BY ?graph")
      end

      def self.delete_graph(graph_name)
        EOL::Sparql.delete_graph(graph_name)
      end

      # Virtuoso data is getting posted to upload_uri
      # see http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main/VirtRDFInsert#HTTP POST Example 1
      def initialize(options = {})
        @upload_uri = options[:upload_uri]
        super(options)
      end

      def insert_data(options = {})
        return false unless EolConfig.data?
        return false if options[:data].blank?
        options[:data].in_groups_of(10_000, false) do |group|
          triples = group.join(" .\n")
          EOL.log("inserting #{group.count} triples", prefix: ".")
          query = "INSERT DATA INTO <#{options[:graph_name]}> { #{triples} }"
          uri = URI(upload_uri)
          request = Net::HTTP::Post.new(uri.request_uri)
          request.basic_auth(username, password)
          request.body = "#{namespaces_prefixes} #{query}"
          request.content_type = 'application/sparql-query'

          response = Net::HTTP.start(uri.host, uri.port) do |http|
            http.open_timeout = 30
            http.read_timeout = 240
            http.request(request)
          end

          if response.code.to_i != 201 && Rails.logger
            Rails.logger.error "** SOME DATA FAILED TO LOAD IN VIRTUOSO:"
            Rails.logger.error "** Graph: #{options[:graph_name]}"
            Rails.logger.error "** URI: #{uri.request_uri}"
            Rails.logger.error "** User: #{username}"
            Rails.logger.error "** Namespaces prefixes: #{namespaces_prefixes}"
            Rails.logger.error "** Query: #{query}"
            Rails.logger.error "** Response class: #{response.class_name}"
            return false
          end
        end
        true
      end
    end
  end
end
