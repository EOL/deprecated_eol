module EOL
  module Api
    module Traits
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = ""
        DESCRIPTION = ""
        PARAMETERS = Proc.new {
          [
            EOL::Api::DocumentationParameter.new(
              :name => 'id',
              :type => Integer,
              :required => true)
          ] }

        def self.call(params={})
          validate_and_normalize_input_parameters!(params)
          begin
            taxon_concept = TaxonConcept.find(params[:id])
          rescue
            raise ActiveRecord::RecordNotFound.new("Unknown page id \"#{params[:id]}\"")
          end
          raise ActiveRecord::RecordNotFound.new("Page \"#{params[:id]}\" is no longer available") if !taxon_concept.published?
          prepare_hash(taxon_concept, params)
        end

        def self.prepare_hash(taxon_concept, params={})
          taxon_page = TaxonPage.new(taxon_concept)
          data = params[:data] || taxon_page.data
          data = data.get_data
          jsonld = jsonld_header
          jsonld['@graph'] = [ taxon_concept.to_jsonld ]
          if Hierarchy.wikipedia && wikipedia_entry = taxon_concept.entry(Hierarchy.wikipedia)
            jsonld['@graph'] << wikipedia_entry.mapping_jsonld
          end
          jsonld['@graph'] += taxon_concept.common_names.collect{ |tcn| tcn.to_jsonld }
          jsonld['@graph'] += data.collect{ |d| d.to_jsonld }
          return jsonld
        end

        def self.jsonld_header
          { '@context' => {
              'dc' => 'http://purl.org/dc/terms/',
              'dwc' => 'http://rs.tdwg.org/dwc/terms/',
              'eol' => 'http://eol.org/schema/',
              'eolterms' => 'http://eol.org/schema/terms/',
              'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
              'gbif' => 'http://rs.gbif.org/terms/1.0/',
              'foaf' => 'http://xmlns.com/foaf/0.1/',
              'dwc:taxonID' => { '@type' => '@id' },
              'dwc:resourceID' => { '@type' => '@id' },
              'dwc:relatedResourceID' => { '@type' => '@id' },
              'dwc:relationshipOfResource' => { '@type' => '@id' },
              'eol:associationType' => { '@type' => '@id' },
              'dwc:vernacularName' => { '@container' => '@language' },
              'rdfs:label' => { '@container' => '@language' } } }
        end

      end
    end
  end
end
