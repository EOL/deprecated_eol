module EOL
  module Sparql

    def self.common_namespaces
      {
        'dwc' => 'http://rs.tdwg.org/dwc/terms/',
        'dwct' => 'http://rs.tdwg.org/dwc/dwctype/',
        'dc' => 'http://purl.org/dc/terms/',
        'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
        'foaf' => 'http://xmlns.com/foaf/0.1/',
        'eol' => 'http://eol.org/schema/terms/',
        'obis' => 'http://iobis.org/schema/terms/',
        'owl' => 'http://www.w3.org/2002/07/owl#',
        'anage' => 'http://anage.org/schema/terms/'
      }
    end

    def self.four_store_connection
      EOL::Sparql::FourStoreEndpoint.new(
        :endpoint_uri => 'http://localhost:8000/sparql/',
        :action_uri => 'http://localhost:8000/')
    end

    def self.virtuoso_connection
      EOL::Sparql::VirtuosoEndpoint.new(
        :endpoint_uri => 'http://localhost:8890/sparql',
        :upload_uri => 'http://localhost:8890/DAV/xx/yy',
        :username => 'demo',
        :password => 'demo')
    end

    def self.to_underscore(str)
      convert(str.downcase.tr(' ','_'))
    end

    def self.convert(str)
       str.gsub!("&", "&amp;")
       str.gsub!("<", "&lt;")
       str.gsub!(">", "&gt;")
       str.gsub!("'", "&apos;")
       str.gsub!("\"", "&quot;")
       str.gsub!("\\", "")
       str.gsub!("\n", "")
       str.gsub!("\r", "")
       str
    end

  end
end