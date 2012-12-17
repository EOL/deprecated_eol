module EOL
  module Api
    module Pages
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = I18n.t(:pages_method_description)
        DESCRIPTION = begin
          hierarchy_entries_url = url_for(:controller => '/api/docs', :action => 'hierarchy_entries')
          I18n.t(:page_method_description) + '</p><p>' +
          I18n.t('the_darwin_core_taxon_elements') + ' ' +
          I18n.t('for_example_for_the_taxon_element_for_a_node',
            :link => view_context.link_to('hierarchy_entries', hierarchy_entries_url)) + ' ' +
          I18n.t('there_is_no_singular_eol',
            :link => view_context.link_to('hierarchy_entries', hierarchy_entries_url)) + '</p><p>' +
          I18n.t('if_the_details_parameter_is_not_set',
            :linka => view_context.link_to(I18n.t('dublin_core'), 'http://dublincore.org/documents/dcmi-type-vocabulary/'),
            :linkb=> view_context.link_to(I18n.t('species_profile_model'), 'http://rs.tdwg.org/ontology/voc/SPMInfoItems'))
        end
        PARAMETERS =
          [
            EOL::Api::DocumentationParameter.new(
              :name => 'id',
              :type => Integer,
              :required => true,
              :test_value => (TaxonConcept.find_by_id(1045608) || TaxonConcept.last).id ),
            EOL::Api::DocumentationParameter.new(
              :name => 'images',
              :type => Integer,
              :values => (0..75),
              :default => 1,
              :test_value => 2,
              :notes => I18n.t('limits_the_number_of_returned_image_objects') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'videos',
              :type => Integer,
              :values => (0..75),
              :default => 1,
              :test_value => 0,
              :notes => I18n.t('limits_the_number_of_returned_video_objects') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'sounds',
              :type => Integer,
              :values => (0..75),
              :default => 0,
              :notes => I18n.t('limits_the_number_of_returned_sound_objects') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'maps',
              :type => Integer,
              :values => (0..75),
              :default => 0,
              :notes => I18n.t('limits_the_number_of_returned_map_objects') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'text',
              :type => Integer,
              :values => (0..75),
              :default => 1,
              :test_value => 2,
              :notes => I18n.t('limits_the_number_of_returned_text_objects') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'iucn',
              :type => 'Boolean',
              :notes => I18n.t('limits_the_number_of_returned_iucn_objects') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'subjects',
              :type => String,
              :values => I18n.t('see_notes'),
              :default => 'overview',
              :notes => I18n.t('a_pipe_delimited_list_of_spm_info_item_subject_names') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'licenses',
              :type => String,
              :values => [ 'cc-by', 'cc-by-nc', 'cc-by-sa', 'cc-by-nc-sa', 'pd', 'na', 'all' ],
              :default => 'all',
              :notes => I18n.t('a_pipe_delimited_list_of_licenses', :creative_commons_link =>
                view_context.link_to(I18n.t('creative_commons'), 'http://creativecommons.org/licenses/', :rel => :nofollow)) ),
            EOL::Api::DocumentationParameter.new(
              :name => 'details',
              :type => 'Boolean',
              :test_value => true,
              :notes => I18n.t('include_all_metadata') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'common_names',
              :type => 'Boolean',
              :test_value => true,
              :notes => I18n.t('return_common_names_for_the_page_taxon') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'vetted',
              :type => Integer,
              :values => [ 0, 1, 2 ],
              :default => 0,
              :notes => I18n.t('return_content_by_vettedness') ),
          ]

        def self.call(params={})
          validate_and_normalize_input_parameters!(params)
          params[:details] = 1 if params[:format] == 'html'
          begin
            taxon_concept = TaxonConcept.find(params[:id], :include => { :published_hierarchy_entries => [ :hierarchy, :name, :rank ] })
          rescue
            raise EOL::Exceptions::ApiException.new("Unknown page id \"#{params[:id]}\"")
          end
          raise EOL::Exceptions::ApiException.new("Page \"#{params[:id]}\" is no longer available") if !taxon_concept.published?
          prepare_hash(taxon_concept, params)
        end

        def self.prepare_hash(taxon_concept, params={})
          return_hash = {}
          return_hash['identifier'] = taxon_concept.id
          return_hash['scientificName'] = taxon_concept.entry.name.string
          return_hash['richness_score'] = taxon_concept.taxon_concept_metric.richness_for_display(5) rescue 0

          return_hash['synonyms'] = []
          if params[:synonyms]
            taxon_concept.scientific_synonyms.each do |syn|
              relation = syn.synonym_relation ? syn.synonym_relation.label : ''
              return_hash['synonyms'] << {
                'synonym' => syn.name.string,
                'relationship' => relation
              }
            end
          end

          return_hash['vernacularNames'] = []
          if params[:common_names]
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
          end

          return_hash['taxonConcepts'] = []
          taxon_concept.curated_hierarchy_entries.each do |entry|
            entry_hash = {
              'identifier'      => entry.id,
              'scientificName'  => entry.name.string,
              'nameAccordingTo' => entry.hierarchy.label,
              'canonicalForm'   => (entry.name.canonical_form.string rescue '')
            }
            entry_hash['sourceIdentfier'] = entry.identifier unless entry.identifier.blank?
            entry_hash['taxonRank'] = entry.rank.label.firstcap unless entry.rank.nil?
            entry_hash['hierarchyEntry'] = entry unless params[:format] == 'json'
            return_hash['taxonConcepts'] << entry_hash
          end

          return_hash['dataObjects'] = []
          data_objects = params[:data_object] ? [ params[:data_object] ] : taxon_concept.data_objects_for_api(params)
          data_objects.each do |data_object|
            return_hash['dataObjects'] << EOL::Api::DataObjects::V1_0.prepare_hash(data_object, params)
          end
          return return_hash
        end
      end
    end
  end
end
