module EOL
  module Api
    module Pages
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        DEFAULT_OBJECTS_NUMBER = 1
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
              :name => 'batch',
              :type => 'Boolean',
              :test_value => false,
              :notes => I18n.t('returns_either_a_batch_or_not') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'id',
              :type => String,
              :required => true,
              :test_value => (TaxonConcept.find_by_id(1045608) || TaxonConcept.last).id ),
            EOL::Api::DocumentationParameter.new(
              :name => 'images_per_page',
              :type => Integer,
              :values => (0..75),
              :test_value => 2,
              :notes => I18n.t('limits_the_number_of_returned_image_objects') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'images_page',
              :type => Integer,
              :default => 1,
              :test_value => 1,
              :notes => I18n.t('image_objects_page_number') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'videos_per_page',
              :type => Integer,
              :values => (0..75),
              :test_value => 0,
              :notes => I18n.t('limits_the_number_of_returned_video_objects') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'videos_page',
              :type => Integer,
              :default => 1,
              :test_value => 1,
              :notes => I18n.t('video_objects_page_number') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'sounds_per_page',
              :type => Integer,
              :values => (0..75),
              :notes => I18n.t('limits_the_number_of_returned_sound_objects') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'sounds_page',
              :type => Integer,
              :default => 1,
              :test_value => 1,
              :notes => I18n.t('sound_objects_page_number') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'maps_per_page',
              :type => Integer,
              :values => (0..75),
              :notes => I18n.t('limits_the_number_of_returned_map_objects') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'maps_page',
              :type => Integer,
              :default => 1,
              :test_value => 1,
              :notes => I18n.t('map_objects_page_number') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'texts_per_page',
              :type => Integer,
              :values => (0..75),
              :test_value => 2,
              :notes => I18n.t('limits_the_number_of_returned_text_objects') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'texts_page',
              :type => Integer,
              :default => 1,
              :test_value => 1,
              :notes => I18n.t('text_objects_page_number') ),
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
              :name => 'taxonomy',
              :type => 'Boolean',
              :default => true,
              :test_value => true,
              :default => true,
              :notes => I18n.t('return_any_taxonomy_details_from_different_hierarchy_providers') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'vetted',
              :type => Integer,
              values:  [ 0, 1, 2, 3, 4 ],
              :default => 0,
              :notes => I18n.t('return_content_by_vettedness') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'cache_ttl',
              :type => Integer,
              :notes => I18n.t('api_cache_time_to_live_parameter')),
            EOL::Api::DocumentationParameter.new(
                :name => "language",
                :type => String,
                :values => Language.approved_languages.collect(&:iso_639_1),
                :default => "en",
                :notes => I18n.t(:limits_the_returned_to_a_specific_language))
          ] }

        def self.call(params={})
          validate_and_normalize_input_parameters!(params)
          adjust_sounds_images_videos_texts!(params)
          params[:details] = 1 if params[:format] == 'html'
          I18n.locale = params[:language] unless params[:language].blank?
          # NOTE: we need to honor supercedure, so this is slower than ideal:
          taxon_concepts = params[:id].split(",").map do |id|
            super_id = TaxonConcept.find(id).try(:id)
            TaxonConcept.with_titles.find(super_id) if super_id
          end.compact
          if (params[:batch] || taxon_concepts.count > 1)
            batch_concepts = []
            taxon_concepts.each do |taxon_concept|
              raise ActiveRecord::RecordNotFound.new("Unknown page id \"#{params[:id]}\"") unless taxon_concept
              raise ActiveRecord::RecordNotFound.new("Page \"#{taxon_concept.id}\" is no longer available") unless taxon_concept.published?
              batch_concepts.push(prepare_hash(taxon_concept, params))
            end
            batch_concepts
          else
            taxon_concept = taxon_concepts.first
            raise ActiveRecord::RecordNotFound.new("Unknown page id \"#{params[:id]}\"") unless taxon_concept
            raise ActiveRecord::RecordNotFound.new("Page \"#{taxon_concept.id}\" is no longer available") unless taxon_concept.published?
            prepare_hash(taxon_concept, params)
          end
        end

        def self.adjust_sounds_images_videos_texts!(params)
          params[:images_per_page] = adjust_param(params[:images_per_page], params[:images])
          params[:sounds_per_page] = adjust_param(params[:sounds_per_page], params[:sounds])
          params[:videos_per_page] = adjust_param(params[:videos_per_page], params[:videos])
          params[:maps_per_page] = adjust_param(params[:maps_per_page], params[:maps])
          params[:texts_per_page] = adjust_param(params[:texts_per_page], params[:texts])
          # debugger
          params
        end

        def self.adjust_param(param_per_page, param)
          val = param_per_page.blank? ? param : param_per_page
          val.blank? ? DEFAULT_OBJECTS_NUMBER : val.to_i
        end

        def self.prepare_hash(taxon_concept, params={})
          return_hash = {}
          unless taxon_concept.nil?
            return_hash['identifier'] = taxon_concept.id
            return_hash['scientificName'] = taxon_concept.entry.name.string
            return_hash['exemplar'] = params[:data_object].is_exemplar_for?(taxon_concept.id) if
              params[:data_object]
            return_hash['richness_score'] = taxon_concept.taxon_concept_metric.richness_for_display(5) rescue 0

            if params[:synonyms]
              return_hash["synonyms"] =
              taxon_concept.scientific_synonyms.
                includes([:name, :synonym_relation, :hierarchy]).
                map do |syn|
                relation = syn.synonym_relation.try(:label) || ""
                resource_title = syn.hierarchy.try(:resource).try(:title) || "" #try returns nil when called on nil
                { "synonym" => syn.name.string, "relationship" => relation, "resource" => resource_title}
              end.sort {|a,b| a["synonym"] <=> b["synonym"] }.uniq
            end

            if params[:common_names]
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
            end

            if params[:references]
              return_hash['references'] = []
              references = Ref.find_refs_for(taxon_concept.id)
              references = Ref.sort_by_full_reference(references)
              references.each do |r|
                return_hash['references'] << r.full_reference
              end
              return_hash['references'].uniq!
            end

            if params[:taxonomy]
              return_hash['taxonConcepts'] = []
              taxon_concept.published_sorted_hierarchy_entries_for_api.each do |entry|
                entry_hash = {
                  'identifier'      => entry.id,
                  'scientificName'  => entry.name.string,
                  'nameAccordingTo' => entry.hierarchy.label,
                  'canonicalForm'   => (entry.name.canonical_form.string rescue '')
                }
                entry_hash['sourceIdentifier'] = entry.identifier unless entry.identifier.blank?
                entry_hash['taxonRank'] = entry.rank.label.firstcap unless entry.rank.nil?
                entry_hash['hierarchyEntry'] = entry unless params[:format] == 'json'
                return_hash['taxonConcepts'] << entry_hash
              end
            end
          end
          unless no_objects_required?(params.dup)
            return_hash['dataObjects'] = []
            data_objects = params[:data_object] ? [ params[:data_object] ] : get_data_objects(taxon_concept, params)
            data_objects.each do |data_object|
              return_hash['dataObjects'] << EOL::Api::DataObjects::V1_0.prepare_hash(data_object, params)
            end
          end

          if params[:batch]
            batch_hash = {}
            batch_hash[taxon_concept.id] = return_hash
            return batch_hash
          end
          return return_hash
        end

        def self.get_data_objects(taxon_concept, options={})
          # setting some default search options which will get sent to the Solr methods
          solr_search_params = {}
          solr_search_params[:sort_by] = 'status'
          solr_search_params[:visibility_types] = ['visible']
          if options[:vetted] == 1  # 1 = trusted
            solr_search_params[:vetted_types] = ['trusted']
          elsif options[:vetted] == 2  # 2 = everything except untrusted
            solr_search_params[:vetted_types] = ['trusted', 'unreviewed']
          elsif options[:vetted] == 3  # 3 = unreviewed
            solr_search_params[:vetted_types] = ["unreviewed"]
          elsif options[:vetted] == 4  # 4 = untrusted
            solr_search_params[:vetted_types] = ["untrusted"]
          else  # 0 = everything
            solr_search_params[:vetted_types] = ['trusted', 'unreviewed', 'untrusted']
          end
          options[:vetted_types] = solr_search_params[:vetted_types]

          license = options[:licenses]
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
          TaxonUserClassificationFilter.preload_details(all_data_objects)
          # sorting after the preloading has happened
          text_objects = sort_and_promote_text(taxon_concept, text_objects, options) if options[:texts_per_page] && options[:texts_per_page] > 0
          all_data_objects = [ text_objects, image_objects, video_objects, sound_objects, map_objects ].flatten.compact

          if options[:iucn]
            iucn_object = taxon_concept.iucn
            all_data_objects << iucn_object if iucn_object
          end

          # preload necessary associations for API response
          DataObject.preload_associations(all_data_objects, [
            :users_data_object, { :agents_data_objects => [ :agent, :agent_role ] }, :published_refs, :audiences ] )
          options[:licenses] = license
          all_data_objects
        end

        def self.process_license_options!(options)
          if options[:licenses]
            options[:licenses] = options[:licenses].split("|").flat_map do |l|
              l = 'public domain' if l == 'pd'
              l = 'not applicable' if l == 'na'
              License.find(:all, :conditions => "title REGEXP '^#{l}([^-]|$)'")
            end.compact
          end
        end

        def self.process_subject_options!(options)
          options[:subjects] ||= ""
          options[:text_subjects] = options[:subjects].split("|")
          options[:text_subjects] << 'Uses' if options[:text_subjects].include?('Use')
          if options[:subjects].blank? || options[:text_subjects].include?('overview') || options[:text_subjects].include?('all')
            options[:text_subjects] = nil
          else
            options[:text_subjects] = options[:text_subjects].flat_map { |l| InfoItem.cached_find_translated(:label, l, 'en', :find_all => true) }.compact
            options[:toc_items] = options[:text_subjects].flat_map { |ii| ii.toc_item }.compact
          end
        end

        def self.load_text(taxon_concept, options, solr_search_params)
          text_objects = []
          if params_found_and_greater_than_zero(options[:texts_page], options[:texts_per_page])
            text_objects = taxon_concept.data_objects_from_solr(solr_search_params.merge({
              page: options[:texts_page],
              per_page: options[:texts_per_page],
              toc_ids: options[:toc_items] ? options[:toc_items].collect(&:id) : nil,
              data_type_ids: DataType.text_type_ids,
              filter_by_subtype: false
            }))
          end
          return text_objects
        end

        def self.sort_and_promote_text(taxon_concept, text_objects, options)
          DataObject.preload_associations(text_objects, [ :toc_items, { :info_items => :translations } ] )
          text_objects = DataObject.sort_by_rating(text_objects, taxon_concept)
          # TODO - the overview_text_for_user does a better job of handling anonymous users if you don't pass a user at all:
          user = User.new(:language => Language.default)
          exemplar_text = taxon_concept.overview_text_for_user(user)
          promote_exemplar!(exemplar_text, text_objects, options)
          text_objects
        end

        def self.load_images(taxon_concept, options, solr_search_params)
          image_objects = []
          if params_found_and_greater_than_zero(options[:images_page], options[:images_per_page])
            image_objects = taxon_concept.data_objects_from_solr(solr_search_params.merge({
              page: options[:images_page],
              per_page: options[:images_per_page],
              data_type_ids: DataType.image_type_ids,
              return_hierarchically_aggregated_objects: true
            }))
            exemplar_image = taxon_concept.published_exemplar_image
            promote_exemplar!(exemplar_image, image_objects, options)
          end
          return image_objects
        end

        def self.params_found_and_greater_than_zero(page, per_page)
          page && per_page && page > 0 && per_page > 0 ? true : false
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
          existing_objects_of_same_type.delete_if { |d| d.guid == exemplar_object.guid }
          # prepend the exemplar
          existing_objects_of_same_type.unshift(exemplar_object)
          # if the exemplar increased the size of our image array, remove the last one
          existing_objects_of_same_type.pop if existing_objects_of_same_type.length > original_length && original_length != 0
        end

        def self.load_videos(taxon_concept, options, solr_search_params)
          video_objects = []
          if params_found_and_greater_than_zero(options[:videos_page], options[:videos_per_page])
            video_objects = taxon_concept.data_objects_from_solr(solr_search_params.merge({
              page: options[:videos_page],
              per_page: options[:videos_per_page],
              data_type_ids: DataType.video_type_ids,
              return_hierarchically_aggregated_objects: true,
              filter_by_subtype: false
            }))
            video_objects.each{ |d| d.data_type = DataType.video }
          end
          return video_objects
        end

        def self.load_sounds(taxon_concept, options, solr_search_params)
          sound_objects = []
          if params_found_and_greater_than_zero(options[:sounds_page], options[:sounds_per_page])
            sound_objects = taxon_concept.data_objects_from_solr(solr_search_params.merge({
              page: options[:sounds_page],
              per_page: options[:sounds_per_page],
              data_type_ids: DataType.sound_type_ids,
              return_hierarchically_aggregated_objects: true,
              filter_by_subtype: false
            }))
          end
          return sound_objects
        end

        def self.load_maps(taxon_concept, options, solr_search_params)
          map_objects = []
          if params_found_and_greater_than_zero(options[:maps_page], options[:maps_per_page])
            map_objects = taxon_concept.data_objects_from_solr(solr_search_params.merge({
              page: options[:maps_page],
              per_page: options[:maps_per_page],
              data_type_ids: DataType.image_type_ids,
              data_subtype_ids: DataType.map_type_ids
            }))
          end
          return map_objects
        end
        def self.no_objects_required?(params)
          return ( params[:action] == "pages" &&
                   params[:texts_per_page] == 0 &&
                   params[:images_per_page] == 0 &&
                   params[:videos_per_page] == 0 &&
                   ( params[:maps_per_page] == 0 || !params.has_key?(:maps_per_page) ) &&
                   ( params[:sounds_per_page] == 0 || !params.has_key?(:sounds_per_page) )
                 )
        end
        class << self
          private :no_objects_required?
        end
      end
    end
  end
end
