# encoding: utf-8
require 'net/http'
require 'uri'
require 'nokogiri'

class SchemaTermParser

  def self.parse_terms_from(url)
    return unless url
    xml = Nokogiri.XML(http_get(url))
    schema_type = type_of_schema(xml)
    case schema_type
    when :rdfs_owl
      return parse_rdfs_owl(xml)
    else
      raise "Unrecognized schema type"
    end
  end

  def self.namespaces
    {
      'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      'owl' => 'http://www.w3.org/2002/07/owl#',
      'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
      'skos' => 'http://www.w3.org/2004/02/skos/core#',
      'obo' => 'http://purl.obolibrary.org/obo/',
      'oboInOwl' => 'http://www.geneontology.org/formats/oboInOwl#',
      'dcterms' => 'http://purl.org/dc/terms/'
    }
  end

  def self.attribute_uris
    [ 'rdfs:label', 'obo:IAO_0000115', 'rdfs:comment', 'skos:note', 'dcterms:title', 'dcterms:description']
  end

  def self.parse_rdfs_owl(xml)
    term_types = [ '/rdf:RDF/rdf:Description', '/rdf:RDF/owl:Class' ]
    terms = {}
    term_types.each do |term_type|
      xml.xpath(term_type, namespaces).each do |description|
        if about = description.attribute('about')
          uri = about.value.strip
          terms[uri] ||= {}
          attribute_uris.each do |att|
            description.xpath(att, namespaces).each do |l|
              text = l.text.strip
              next if text.blank?
              language = l.attribute('lang') ? l.attribute('lang').value.strip : nil
              terms[uri][att] ||= []
              terms[uri][att] << { :text => text, :language => language }
            end
          end
        end
      end
    end
    terms.delete_if{ |uri, metadata| metadata['rdfs:label'].blank? }
    terms
  end

  def self.type_of_schema(xml)
    return :rdfs_owl if xml.xpath('/rdf:RDF/rdf:Description', namespaces).any? ||
                        xml.xpath('/rdf:RDF/owl:Class', namespaces).any?
  end

  def self.http_get(url)
    Net::HTTP.get(URI.parse(url))
  end

end
