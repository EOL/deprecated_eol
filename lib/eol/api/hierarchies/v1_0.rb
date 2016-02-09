module EOL
  module Api
    module Hierarchies
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = Proc.new { I18n.t(:method_to_get_metadata_about_the_hierarchy) }
        DESCRIPTION = Proc.new { I18n.t('hierarchies_description') }
        PARAMETERS = Proc.new {
          [
            EOL::Api::DocumentationParameter.new(
              :name => 'id',
              :type => Integer,
              :required => true,
              :test_value => Hierarchy.col.id ),
            EOL::Api::DocumentationParameter.new(
              :name => 'cache_ttl',
              :type => Integer,
              :notes => I18n.t('api_cache_time_to_live_parameter')),
               EOL::Api::DocumentationParameter.new(
                name: "language",
                type: String,
                values: Language.approved_languages.collect(&:iso_639_1),
                default: "en",
                notes: I18n.t(:limits_the_returned_to_a_specific_language))
          ] }

        def self.call(params={})
          validate_and_normalize_input_parameters!(params)
          I18n.locale = params[:language] unless params[:language].blank?
          begin
            hierarchy = Hierarchy.find(params[:id])
            Hierarchy.preload_associations(hierarchy, { :kingdoms => [ :rank, :name ] })
          rescue
            raise ActiveRecord::RecordNotFound.new("Unknown hierarchy id \"#{params[:id]}\"")
          end
          raise ActiveRecord::RecordNotFound.new("Hierarchy #{id} is currently inaccessible through the API") unless Hierarchy.available_via_api.include?(hierarchy)
          prepare_hash(hierarchy)
        end

        def self.prepare_hash(hierarchy, params={})
          return_hash = {}
          return_hash['title'] = hierarchy.label
          return_hash['contributor'] = hierarchy.agent.full_name
          return_hash['dateSubmitted'] = hierarchy.indexed_on.mysql_timestamp
          return_hash['source'] = hierarchy.url

          return_hash['roots'] = []
          hierarchy.kingdoms.each do |root|
            root_hash = {}
            root_hash['sourceIdentifier'] = root.identifier unless root.identifier.blank?
            root_hash['taxonID'] = root.id
            root_hash['parentNameUsageID'] = root.parent_id
            root_hash['taxonConceptID'] = root.taxon_concept_id
            root_hash['scientificName'] = root.name.string.firstcap
            root_hash['taxonRank'] = root.rank.label unless root.rank_id == 0 || root.rank.blank?
            return_hash['roots'] << root_hash
          end
          return return_hash
        end

      end
    end
  end
end
