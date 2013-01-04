module EOL
  module Api
    module DataObjects
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = Proc.new { I18n.t(:returns_all_metadata_about_a_particular_data_object) }
        DESCRIPTION = Proc.new { I18n.t('data_object_api_description') + '</p><p>' + I18n.t('image_objects_will_contain_two_mediaurl_elements') }
        TEMPLATE = '/api/pages_0_4'
        PARAMETERS = Proc.new {
          [
            EOL::Api::DocumentationParameter.new(
              :name => 'id',
              :type => String,
              :required => true,
              :test_value => (DataObject.latest_published_version_of_guid('d72801627bf4adf1a38d9c5f10cc767f') || DataObject.last).id,
              :notes => I18n.t('the_data_object_id_can_be') )
          ] }

        def self.call(params={})
          validate_and_normalize_input_parameters!(params)
          params[:details] = true
          if params[:id].is_numeric?
            begin
              data_object = DataObject.find(params[:id])
            rescue
              raise EOL::Exceptions::ApiException.new("Unknown data_object id \"#{params[:id]}\"")
            end
          else
            data_object = DataObject.find_by_guid(params[:id])
            raise EOL::Exceptions::ApiException.new("Unknown data_object id \"#{params[:id]}\"") if data_object.blank?
            latest_version = data_object.latest_version_in_same_language(:check_only_published => true)
            if latest_version.blank?
              latest_version = data_object.latest_version_in_same_language(:check_only_published => false)
            end
            data_object = DataObject.find_by_id(latest_version.id)
          end

          taxon_concept = data_object.all_associations.first.taxon_concept
          EOL::Api::Pages::V1_0.prepare_hash(taxon_concept, params.merge({ :data_object => data_object, :details => true }))
        end

        def self.prepare_hash(data_object, params={})
          return_hash = {}
          return_hash['identifier'] = data_object.guid
          return_hash['dataObjectVersionID'] = data_object.id
          return_hash['dataType'] = data_object.data_type.schema_value
          return_hash['dataSubtype'] = data_object.data_subtype.label rescue ''
          return_hash['vettedStatus'] = data_object.association_with_best_vetted_status.vetted.label unless data_object.association_with_best_vetted_status.vetted.blank?
          return_hash['dataRating'] = data_object.data_rating
          if data_object.is_text?
            if data_object.created_by_user? && !data_object.toc_items.blank?
              return_hash['subject']            = data_object.toc_items[0].info_items[0].schema_value unless data_object.toc_items[0].info_items.blank?
            else
              return_hash['subject']            = data_object.info_items[0].schema_value unless data_object.info_items.blank?
            end
          end
          return return_hash unless params[:details] == true

          return_hash['mimeType']               = data_object.mime_type.label unless data_object.mime_type.blank?
          if return_hash['mimeType'].blank? && data_object.image?
            return_hash['mimeType'] = 'image/jpeg'
          end
          return_hash['created']                = data_object.object_created_at unless data_object.object_created_at.blank?
          return_hash['modified']               = data_object.object_modified_at unless data_object.object_modified_at.blank?
          return_hash['title']                  = data_object.object_title unless data_object.object_title.blank?
          return_hash['language']               = data_object.language.iso_639_1 unless data_object.language.blank?
          return_hash['license']                = data_object.license.source_url unless data_object.license.blank?
          return_hash['rights']                 = data_object.rights_statement unless data_object.rights_statement.blank?
          return_hash['rightsHolder']           = data_object.rights_holder unless data_object.rights_holder.blank?
          return_hash['bibliographicCitation']  = data_object.bibliographic_citation unless data_object.bibliographic_citation.blank?
          return_hash['source']                 = data_object.source_url unless data_object.source_url.blank?
          return_hash['description']            = data_object.description unless data_object.description.blank?
          return_hash['mediaURL']               = data_object.object_url unless data_object.object_url.blank?
          if data_object.is_image?
            return_hash['eolMediaURL']          = DataObject.image_cache_path(data_object.object_cache_url, :orig, $SINGLE_DOMAIN_CONTENT_SERVER) unless data_object.object_cache_url.blank?
            return_hash['eolThumbnailURL']      = DataObject.image_cache_path(data_object.object_cache_url, '98_68', $SINGLE_DOMAIN_CONTENT_SERVER) unless data_object.object_cache_url.blank?
          elsif data_object.is_video?
            return_hash['eolMediaURL']          = data_object.video_url unless data_object.video_url.blank? || data_object.video_url == data_object.object_url
            return_hash['eolThumbnailURL']      = DataObject.image_cache_path(data_object.thumbnail_cache_url, '260_190', $SINGLE_DOMAIN_CONTENT_SERVER) unless data_object.thumbnail_cache_url.blank?
          elsif data_object.is_sound?
            return_hash['eolMediaURL']          = data_object.sound_url unless data_object.sound_url.blank? || data_object.sound_url == data_object.object_url
            return_hash['eolThumbnailURL']      = DataObject.image_cache_path(data_object.thumbnail_cache_url, '260_190', $SINGLE_DOMAIN_CONTENT_SERVER) unless data_object.thumbnail_cache_url.blank?
          end

          return_hash['location']               = data_object.location unless data_object.location.blank?

          unless data_object.latitude == 0 && data_object.longitude == 0 && data_object.altitude == 0
            return_hash['latitude'] = data_object.latitude unless data_object.latitude == 0
            return_hash['longitude'] = data_object.longitude unless data_object.longitude == 0
            return_hash['altitude'] = data_object.altitude unless data_object.altitude == 0
          end

          return_hash['agents'] = []
          if udo = data_object.users_data_object
            return_hash['agents'] << {
              'full_name' => data_object.user.full_name,
              'homepage'  => "",
              'role'      => (AgentRole.author.label.downcase rescue nil)
            }
            return_hash['agents'] << {
              'full_name' => data_object.user.full_name,
              'homepage'  => "",
              'role'      => (AgentRole.provider.label.downcase rescue nil)
            }
          else
            data_object.agents_data_objects.each do |ado|
              if ado.agent
                return_hash['agents'] << {
                  'full_name' => ado.agent.full_name,
                  'homepage'  => ado.agent.homepage,
                  'role'      => (ado.agent_role.label.downcase rescue nil)
                }
              end
            end
            if data_object.content_partner
              return_hash['agents'] << {
                'full_name' => data_object.content_partner.name,
                'homepage'  => data_object.content_partner.homepage,
                'role'      => (AgentRole.provider.label.downcase rescue nil)
              }
            end
          end

          return_hash['references'] = []
          data_object.published_refs.each do |r|
            return_hash['references'] << r.full_reference
          end

          return return_hash
        end
      end
    end
  end
end
