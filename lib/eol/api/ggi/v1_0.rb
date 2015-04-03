module EOL
  module Api
    module Ggi
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
          return_hash = {}
          unless taxon_concept.nil?
            return_hash['identifier'] = taxon_concept.id
            return_hash['scientificName'] = taxon_concept.entry.name.string
            return_hash['taxonRank'] = taxon_concept.entry.rank ? taxon_concept.entry.rank.label : nil
            best_image = taxon_concept.exemplar_or_best_image_from_solr
            return_hash['bestImage'] = best_image ? EOL::Api::DataObjects::V1_0.prepare_hash(best_image, details: true) : {}

            return_hash['vernacularNames'] = []
            taxon_concept.common_names.each do |tcn|
              lang = tcn.language ? tcn.language.iso_639_1 : ''
              common_name_hash = {
                'vernacularName' => tcn.name.string,
                'language'       => lang
              }
              preferred = (tcn.preferred == 1) ? true : nil
              common_name_hash['eol_preferred'] = preferred unless preferred.blank?
              return_hash['vernacularNames'] << common_name_hash
            end

            results = TripleStore.ggi(taxon_concept)
            known_uris = KnownUri.from_triplestore(results, keys: [:attribute])
            results.each do |r|
              r[:resource_id] = r[:graph].to_s.split("/").last.to_i
            end
            resources = Resource.select([:id, :title]).
              where(id: results.map { |r| r[:resource_id ] }.uniq)
            return_hash['measurements'] = results.map do |row|
                result_uri = row[:attribute].to_s
                result_value = row[:value].nil? ? "" :
                  row[:value].to_s.gsub(/[^.0-9]/, '').to_i
                result_label = known_uris.find { |uri| uri.uri == result_uri }.
                  try(:name)
                result_label ||= result_uri.split("/").last
                resource_title = resources.
                  find { |r| r.id == row[:resource_id] }.
                  title
                {
                  'resourceID' => row[:resource_id],
                  'source' => resource_title,
                  'measurementType' => result_uri,
                  'label' => result_label,
                  'measurementValue' => result_value
                }
              end
          end
          return_hash
        end
      end
    end
  end
end
