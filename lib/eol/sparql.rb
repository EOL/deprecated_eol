module EOL
  module Sparql

    BASIC_URI_REGEX = /^http:\/\/[^ ]+$/i
    ENCLOSED_URI_REGEX = /^<http:\/\/[^ ]+>$/i
    NAMESPACED_URI_REGEX = /^([a-z0-9_-]{1,30}):(.*)$/i
    # TODO - it would be handy if this read from a config file (or at least added things from a config file):
    NAMESPACES = {
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

    def self.connection
      EOL::Sparql::VirtuosoClient.new(
        :endpoint_uri => 'http://localhost:8890/sparql',
        :upload_uri => 'http://localhost:8890/DAV/xx/yy',
        :username => $VIRTUOSO_USER,
        :password => $VIRTUOSO_PW)
    end

    def self.to_underscore(str)
      convert(str.downcase.tr(' ','_'))
    end

    def self.is_uri?(string)
      return true if string =~ BASIC_URI_REGEX
      return true if string =~ ENCLOSED_URI_REGEX
      return true if string =~ NAMESPACED_URI_REGEX
      false
    end

    def self.enclose_value(value)
      return "<" + value + ">" if value =~ BASIC_URI_REGEX
      "\"" + value + "\""
    end

    # Puts URIs in <brackets>, dereferences namespaces, and quotes literals.
    def self.expand_namespaces(value)
      if value =~ BASIC_URI_REGEX                              # full URI
        return value
      elsif value =~ ENCLOSED_URI_REGEX                        # full URI
        return value
      elsif matches = value.match(NAMESPACED_URI_REGEX)        # namespace
        if full_uri = EOL::Sparql::NAMESPACES[matches[1]]
          return full_uri + matches[2]
        else
          return false  # this is the failure - an unknown namespace was given
        end
      end
      return value                                             # literal value
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
