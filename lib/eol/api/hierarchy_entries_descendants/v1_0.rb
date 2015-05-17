module EOL
  module Api
    module HierarchyEntriesDescendants
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = Proc.new { I18n.t(:gives_access_to_a_single_hierarchy_descendants_by_eol) }
        DESCRIPTION = Proc.new { I18n.t('hierarchies_entries_descendants_description') + '</p><p>' + I18n.t('the_json_response_for_this_method') }
        PARAMETERS = Proc.new {
          [
            EOL::Api::DocumentationParameter.new(
              :name => 'id',
              :type => Integer,
              :required => true,
              :test_value => TaxonConcept.get_entry_id_of_last_published_taxon ),
            EOL::Api::DocumentationParameter.new(
              :name => 'common_names',
              :type => 'Boolean',
              :default => 1,
              :notes => I18n.t('return_all_common_names_for_this_taxon') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'synonyms',
              :type => 'Boolean',
              :default => 1,
              :notes => I18n.t('return_all_synonyms_for_this_taxon') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'cache_ttl',
              :type => Integer,
              :notes => I18n.t('api_cache_time_to_live_parameter'))
          ] }

        def self.call(params={})
          validate_and_normalize_input_parameters!(params)

          begin
            associations = [ { :name => :canonical_form }]
            selects = { :hierarchy_entries => '*', :canonical_forms => [ :id, :string ] }
            if params[:common_names]
              associations << { :common_names => [:name, :language] }
              selects[:languages] = [ :id, :iso_639_1 ]
            end
            if params[:synonyms]
              associations << { :scientific_synonyms => [:name, :synonym_relation] }
            end
            hierarchy_entry = HierarchyEntry.find(params[:id])
            hierarchy_entry.preload_associations(associations, :select => selects)
          rescue
            raise ActiveRecord::RecordNotFound.new("Unknown hierarchy_entry id \"#{params[:id]}\"")
          end
          raise ActiveRecord::RecordNotFound.new("hierarchy_entry \"#{params[:id]}\" is no longer available") if hierarchy_entry.nil?

          prepare_hash(hierarchy_entry, params)
        end

        def self.prepare_hash(hierarchy_entry, params={})
          return_hash = {}
          return_hash['descendants'] = []

          HierarchyEntry.preload_associations(hierarchy_entry, { descendants: [ :rank, :name, :hierarchy ] })
          hierarchy_entry.descendants.order('rank_id DESC').map { |e| return_hash['descendants'] << { sourceIdentifier: e.identifier,
                                                                                                      taxonID: e.id,
                                                                                                      parentNameUsageID: e.parent_id,
                                                                                                      taxonConceptID: e.taxon_concept_id,
                                                                                                      scientificName: (e.name.string if e.name),
                                                                                                      taxonRank: (e.rank.label if e.rank),
                                                                                                      source: e.outlink_url } }
          return return_hash
        end
      end
    end
  end
end
