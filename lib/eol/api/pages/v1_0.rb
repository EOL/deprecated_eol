module EOL
  module Api
    module Pages
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = Proc.new { I18n.t(:pages_method_description) }
        DESCRIPTION = Proc.new {
          hierarchy_entries_url = url_for(:controller => '/api/docs', :action => 'hierarchy_entries')
          I18n.t(:page_method_description) + '</p><p>' +
          I18n.t('the_darwin_core_taxon_elements') + ' ' +
          I18n.t('for_example_for_the_taxon_element_for_a_node',
            :link => view_context.link_to('hierarchy_entries', hierarchy_entries_url)) + ' ' +
          I18n.t('there_is_no_singular_eol',
            :link => view_context.link_to('hierarchy_entries', hierarchy_entries_url)) + '</p><p>' +
          I18n.t('if_the_details_parameter_is_not_set',
            :linka => view_context.link_to(I18n.t('dublin_core'), 'http://dublincore.org/documents/dcmi-type-vocabulary/'),
            :linkb => view_context.link_to(I18n.t('eol_accepted_subjects'), '/info/toc_subjects')) +  '</p><p>' +
          I18n.t('if_multiple_media_objects_are_returned')
        }
        PARAMETERS = Proc.new {
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
              :notes => I18n.t('a_pipe_delimited_list_of_spm_info_item_subject_names', :subjects_text => view_context.link_to(I18n.t('eol_accepted_subjects'), '/info/toc_subjects')) ),
            EOL::Api::DocumentationParameter.new(
              :name => 'licenses',
              :type => String,
              :values => 'cc-by, cc-by-nc, cc-by-sa, cc-by-nc-sa, pd ['+ I18n.t('public_domain') +'], na ['+ I18n.t('not_applicable') +'], all',
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
              :name => 'synonyms',
              :type => 'Boolean',
              :test_value => true,
              :notes => I18n.t('return_synonyms_for_the_page_taxon') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'references',
              :type => 'Boolean',
              :test_value => true,
              :notes => I18n.t('return_references_for_the_page_taxon') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'vetted',
              :type => Integer,
              :values => [ 0, 1, 2 ],
              :default => 0,
              :notes => I18n.t('return_content_by_vettedness') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'cache_ttl',
              :type => Integer,
              :notes => I18n.t('api_cache_time_to_live_parameter'))
          ] }

        def self.call(params={})
          validate_and_normalize_input_parameters!(params)
          params[:details] = 1 if params[:format] == 'html'
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

            return_hash['references'] = []
            if params[:references]
              references = Ref.find_refs_for(taxon_concept.id)
              references = Ref.sort_by_full_reference(references)
              references.each do |r|
                return_hash['references'] << r.full_reference
              end
              return_hash['references'].uniq!
            end

            return_hash['taxonConcepts'] = []
            taxon_concept.published_sorted_hierarchy_entries_for_api.each do |entry|
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
          end

          return_hash['dataObjects'] = []
          data_objects = params[:data_object] ? [ params[:data_object] ] : get_data_objects(taxon_concept, params)
          data_objects.each do |data_object|
            return_hash['dataObjects'] << EOL::Api::DataObjects::V1_0.prepare_hash(data_object, params)
          end
          return return_hash
        end

        def self.get_data_objects(taxon_concept, options={})
          # setting some default search options which will get sent to the Solr methods
          solr_search_params = {}
          solr_search_params[:sort_by] = 'status'
          solr_search_params[:visibility_types] = ['visible']
          solr_search_params[:skip_preload] = true
          if options[:vetted] == 1  # 1 = trusted
            solr_search_params[:vetted_types] = ['trusted']
          elsif options[:vetted] == 2  # 2 = everything except untrusted
            solr_search_params[:vetted_types] = ['trusted', 'unreviewed']
          else  # 0 = everything
            solr_search_params[:vetted_types] = ['trusted', 'unreviewed', 'untrusted']
          end
          options[:vetted_types] = solr_search_params[:vetted_types]

          options[:licenses] = nil if options[:licenses].include?('all')
          process_license_options!(options)
          solr_search_params[:license_ids] = options[:licenses].blank? ? nil : options[:licenses].collect(&:id)
          options[:license_ids] = solr_search_params[:license_ids]
          process_subject_options!(options)

          text_objects = load_text(taxon_concept, options, solr_search_params)
          image_objects = load_images(taxon_concept, options, solr_search_params)
          video_objects = load_videos(taxon_concept, options, solr_search_params)
          sound_objects = load_sounds(taxon_concept, options, solr_search_params)
          map_objects = load_maps(taxon_concept, options, solr_search_params)

          all_data_objects = [ text_objects, image_objects, video_objects, sound_objects, map_objects ].flatten.compact
          if options[:iucn]
            # we create fake IUCN objects if there isn't a real one. Don't use those in the API
            iucn_object = taxon_concept.iucn
            if iucn_object && iucn_object.id
              iucn_object.data_type = DataType.text
              all_data_objects << iucn_object
            end
          end

          # preload necessary associations for API response
          DataObject.preload_associations(all_data_objects, [ { :data_objects_hierarchy_entries => [ :vetted, { :hierarchy_entry => { :hierarchy => :resource } } ] },
            :curated_data_objects_hierarchy_entries, :data_type, :license, :language, :mime_type,
            :users_data_object, { :agents_data_objects => [ :agent, :agent_role ] }, :published_refs, :audiences ] )
          all_data_objects
        end

        def self.process_license_options!(options)
          if options[:licenses]
            options[:licenses] = options[:licenses].split("|").map do |l|
              l = 'public domain' if l == 'pd'
              l = 'not applicable' if l == 'na'
              License.find(:all, :conditions => "title REGEXP '^#{l}([^-]|$)'")
            end.flatten.compact
          end
        end

        def self.process_subject_options!(options)
          options[:subjects] ||= ""
          options[:text_subjects] = options[:subjects].split("|")
          options[:text_subjects] << 'Uses' if options[:text_subjects].include?('Use')
          if options[:subjects].blank? || options[:text_subjects].include?('overview') || options[:text_subjects].include?('all')
            options[:text_subjects] = nil
          else
            options[:text_subjects] = options[:text_subjects].map{ |l| InfoItem.cached_find_translated(:label, l, 'en', :find_all => true) }.flatten.compact
            options[:toc_items] = options[:text_subjects].map{ |ii| ii.toc_item }.flatten.compact
          end
        end

        def self.load_text(taxon_concept, options, solr_search_params)
          text_objects = []
          if options[:text] && options[:text] > 0
            text_objects = taxon_concept.data_objects_from_solr(solr_search_params.merge({
              :per_page => options[:text],
              :toc_ids => options[:toc_items] ? options[:toc_items].collect(&:id) : nil,
              :data_type_ids => DataType.text_type_ids,
              :filter_by_subtype => false
            }))
            DataObject.preload_associations(text_objects, [ { :info_items => :translations } ] )
            text_objects = DataObject.sort_by_rating(text_objects, taxon_concept)
            user = User.new(:language => Language.default)
            exemplar_text = taxon_concept.overview_text_for_user(user)
            promote_exemplar!(exemplar_text, text_objects, options)
          end
          return text_objects
        end

        def self.load_images(taxon_concept, options, solr_search_params)
          image_objects = []
          if options[:images] && options[:images] > 0
            image_objects = taxon_concept.data_objects_from_solr(solr_search_params.merge({
              :per_page => options[:images],
              :data_type_ids => DataType.image_type_ids,
              :return_hierarchically_aggregated_objects => true
            }))
            exemplar_image = taxon_concept.published_exemplar_image
            promote_exemplar!(exemplar_image, image_objects, options)
          end
          return image_objects
        end

        def self.promote_exemplar!(exemplar_object, existing_objects_of_same_type, options={})
          return unless exemplar_object
          # confirm license
          return if options[:license_ids] && !options[:license_ids].include?(exemplar_object.license_id)
          # user array intersection (&) to confirm the subject of the examplar is within range
          return if options[:text_subjects] && (options[:text_subjects] & exemplar_object.toc_items).blank?

          # confirm vetted state
          return unless exemplar_object.vetted
          best_vetted_label = exemplar_object.vetted.label('en').downcase
          best_vetted_label = 'unreviewed' if best_vetted_label == 'unknown'
          return if options[:vetted_types] && ! options[:vetted_types].include?(best_vetted_label)

          # now add in the exemplar, and remove one if the array is now too large
          original_length = existing_objects_of_same_type.length
          # remove the exemplar if it is already in the list
          existing_objects_of_same_type.delete_if{ |d| d.guid == exemplar_object.guid }
          # prepend the exemplar if it exists
          existing_objects_of_same_type.unshift(exemplar_object)
          # if the exemplar increased the size of our image array, remove the last one
          existing_objects_of_same_type.pop if existing_objects_of_same_type.length > original_length && original_length != 0
        end

        def self.load_videos(taxon_concept, options, solr_search_params)
          video_objects = []
          if options[:videos] && options[:videos] > 0
            video_objects = taxon_concept.data_objects_from_solr(solr_search_params.merge({
              :per_page => options[:videos],
              :data_type_ids => DataType.video_type_ids,
              :return_hierarchically_aggregated_objects => true,
              :filter_by_subtype => false
            }))
            video_objects.each{ |d| d.data_type = DataType.video }
          end
          return video_objects
        end

        def self.load_sounds(taxon_concept, options, solr_search_params)
          sound_objects = []
          if options[:sounds] && options[:sounds] > 0
            sound_objects = taxon_concept.data_objects_from_solr(solr_search_params.merge({
              :per_page => options[:sounds],
              :data_type_ids => DataType.sound_type_ids,
              :return_hierarchically_aggregated_objects => true,
              :filter_by_subtype => false
            }))
          end
          return sound_objects
        end

        def self.load_maps(taxon_concept, options, solr_search_params)
          map_objects = []
          if options[:maps] && options[:maps] > 0
            map_objects = taxon_concept.data_objects_from_solr(solr_search_params.merge({
              :per_page => options[:maps],
              :data_type_ids => DataType.image_type_ids,
              :data_subtype_ids => DataType.map_type_ids
            }))
          end
          return map_objects
        end

      end
    end
  end
end
