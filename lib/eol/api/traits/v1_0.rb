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
          I18n.locale = params[:language] unless params[:language].blank?
          begin
            taxon_concept = TaxonConcept.find(params[:id])
          rescue
            raise ActiveRecord::RecordNotFound.new("Unknown page id \"#{params[:id]}\"")
          end
          raise ActiveRecord::RecordNotFound.new("Page \"#{params[:id]}\" is no longer available") if !taxon_concept.published?
          prepare_hash(taxon_concept, params)
        end

        def self.prepare_hash(taxon_concept, params={})
          TaxonData.new(taxon_concept).to_jsonld
        end

      end
    end
  end
end
