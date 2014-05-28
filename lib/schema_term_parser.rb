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
      return parse_rdfs_owl(xml, get_base_uri(xml, url))
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
      'gn' => 'http://www.geonames.org/ontology#',
      'dcterms' => 'http://purl.org/dc/terms/'
    }
  end

  def self.attribute_uris
    [ 'rdfs:label', 'obo:IAO_0000115', 'rdfs:comment', 'skos:note',
      'dcterms:title', 'dcterms:description', 'skos:definition', 'skos:prefLabel' ]
  end

  def self.parse_rdfs_owl(xml, base_uri)
    term_types = [ '/rdf:RDF/rdf:Description', '/rdf:RDF/owl:Class', '/rdf:RDF/gn:Code' ]
    terms = {}
    term_types.each do |term_type|
      xml.xpath(term_type, namespaces).each do |description|
        uri = nil
        if about = description.attribute('about')
          uri = about.value.strip
          if uri[0] == '#'
            uri = base_uri + uri
          end
        elsif description.attribute('value') && defined_by = description.xpath('//rdfs:isDefinedBy')
          if resource = defined_by.attribute('resource')
            uri = resource.value.strip
          end
        end
        if uri
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
    replace_synonymous_uris(terms)
    terms.delete_if{ |uri, metadata| metadata['rdfs:label'].blank? }
    terms
  end

  def self.get_base_uri(xml, url)
    if rdf = xml.xpath('/rdf:RDF')
      if base = rdf.attribute('base')
        return base.value
      end
    end
    return url
  end

  def self.replace_synonymous_uris(terms)
    terms.each do |uri, metadata|
      if metadata['rdfs:label'].blank? && ! metadata['skos:prefLabel'].blank?
        metadata['rdfs:label'] = metadata['skos:prefLabel']
        metadata.delete('skos:prefLabel')
      end
      if metadata['dcterms:description'].blank? && ! metadata['skos:definition'].blank?
        metadata['dcterms:description'] = metadata['skos:definition']
        metadata.delete('skos:definition')
      end
    end
  end

  def self.type_of_schema(xml)
    return :rdfs_owl if xml.xpath('/rdf:RDF/rdf:Description', namespaces).any? ||
                        xml.xpath('/rdf:RDF/owl:Class', namespaces).any?
  end

  def self.http_get(url)
    Net::HTTP.get(URI.parse(url))
  end

end
