module EOL
  module Api
    module HierarchyEntries
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = Proc.new { I18n.t(:gives_access_to_a_single_hierarchy_indexed_by_eol) }
        DESCRIPTION = Proc.new { I18n.t('hierarchies_entries_description') + '</p><p>' + I18n.t('the_json_response_for_this_method') }
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
          if false # TODO: this is more efficient. Really.
            hierarchy_entry = HierarchyEntry.
              where(id: params[:id]).
              includes(name: :canonical_form, flat_ancestors: [:rank, :name],
                children: [:rank, :name]).
              first
          end

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
          return_hash['hierarchy_entry'] = hierarchy_entry unless params[:format] == 'json'
          return_hash['sourceIdentifier'] = hierarchy_entry.identifier unless hierarchy_entry.identifier.blank?
          return_hash['taxonID'] = hierarchy_entry.id
          return_hash['parentNameUsageID'] = hierarchy_entry.parent_id
          return_hash['taxonConceptID'] = hierarchy_entry.taxon_concept_id
          return_hash['scientificName'] = hierarchy_entry.name.string
          return_hash['taxonRank'] = hierarchy_entry.rank.label.firstcap unless hierarchy_entry.rank.nil?
          return_hash['source'] = taxon_entry_overview_url(hierarchy_entry.taxon_concept, hierarchy_entry)

          return_hash['nameAccordingTo'] = []
          hierarchy_entry.agents_roles.each do |agent_role|
            return_hash['nameAccordingTo'] << agent_role.agent.full_name
          end

          return_hash['vernacularNames'] = []
          if params[:common_names]
            hierarchy_entry.common_names.each do |common_name|
              vernacular_name_hash = {}
              vernacular_name_hash['vernacularName'] = common_name.name.string.firstcap
              vernacular_name_hash['language'] = common_name.language ? common_name.language.iso_639_1 : ''
              vernacular_name_hash['id'] = common_name.id unless params[:format] == 'json'
              return_hash['vernacularNames'] << vernacular_name_hash
            end
          end

          return_hash['synonyms'] = []
          if params[:synonyms]
            hierarchy_entry.scientific_synonyms.each do |synonym|
              synonym_hash = {}
              synonym_hash['parentNameUsageID'] = hierarchy_entry.id
              synonym_hash['scientificName'] = synonym.name.string.firstcap
              synonym_hash['taxonomicStatus'] = synonym.synonym_relation.label rescue 'synonym'
              synonym_hash['id'] = synonym.id unless params[:format] == 'json'
              return_hash['synonyms'] << synonym_hash
            end
          end

          return_hash['ancestors'] = []
          HierarchyEntry.preload_associations(hierarchy_entry, { :flat_ancestors => [ :rank, :name ] })
          hierarchy_entry.ancestors.each do |ancestor|
            next if ancestor.id == hierarchy_entry.id
            ancestor_hash = {}
            ancestor_hash['sourceIdentifier'] = ancestor.identifier unless ancestor.identifier.blank?
            ancestor_hash['taxonID'] = ancestor.id
            ancestor_hash['parentNameUsageID'] = ancestor.parent_id
            ancestor_hash['taxonConceptID'] = ancestor.taxon_concept_id
            ancestor_hash['scientificName'] = ancestor.name.string.firstcap
            ancestor_hash['taxonRank'] = ancestor.rank.label unless ancestor.rank_id == 0 || ancestor.rank.blank?
            ancestor_hash['source'] = taxon_entry_overview_url(ancestor.taxon_concept_id, ancestor)
            return_hash['ancestors'] << ancestor_hash
          end

          return_hash['children'] = []
          HierarchyEntry.preload_associations(
            hierarchy_entry, { :children => [ :rank, :name ] }
          )
          hierarchy_entry.children.select { |he| he.published? }.each do |child|
            child_hash = {}
            child_hash['sourceIdentifier'] = child.identifier unless child.identifier.blank?
            child_hash['taxonID'] = child.id
            child_hash['parentNameUsageID'] = child.parent_id
            child_hash['taxonConceptID'] = child.taxon_concept_id
            child_hash['scientificName'] = child.name.string.firstcap
            child_hash['taxonRank'] = child.rank.label unless child.rank_id == 0 || child.rank.blank?
            child_hash['source'] = taxon_entry_overview_url(child.taxon_concept_id, child)
            return_hash['children'] << child_hash
          end
          return return_hash
        end
      end
    end
  end
end
