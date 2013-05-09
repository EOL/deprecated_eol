module EOL
  module Sparql
    class VirtuosoClient < Client

      attr_accessor :upload_uri

      def initialize(options = {})
        @upload_uri = options[:upload_uri]
        super(options)
      end

      # Virtuoso data is getting posted to upload_uri
      # see http://virtuoso.openlinksw.com/dataspace/doc/dav/wiki/Main/VirtRDFInsert#HTTP POST Example 1
      def insert_data(options = {})
        unless options[:data].blank?
          query = namespaces.collect{ |key,value| "PREFIX #{key}: <#{value}>"}.join(" ")
          query += " INSERT DATA INTO <#{options[:graph_name]}> { "+ options[:data].join(" .\n") +" }"
          uri = URI(upload_uri)
          request = Net::HTTP::Post.new(uri.request_uri)
          request.basic_auth(username, password)
          request.body = query
          request.content_type = 'application/sparql-query'

          response = Net::HTTP.start(uri.host, uri.port) do |http|
            http.open_timeout = 30
            http.read_timeout = 240
            http.request(request)
          end

          # TODO - we should pass a logger into the constructor and log to that.
          if response.code.to_i != 201
            puts " ** SOME DATA FAILED TO LOAD IN VIRTUOSO **"
            pp options
          end
        end
      end

    end
  end
end
