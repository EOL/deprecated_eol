module EOL
  module Solr
    class DataObjectsCoreRebuilder
      def self.connect
        SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE)
      end

      def self.obliterate
        solr_api = self.connect
        solr_api.delete_all_documents
      end

      def self.begin_rebuild(options = {})
        options[:optimize] = true unless defined?(options[:optimize])
        solr_api = self.connect
        solr_api.delete_all_documents
        self.start_to_index_data_objects(solr_api)
        solr_api.optimize if options[:optimize]
      end

      def self.start_to_index_data_objects(solr_api)
        start = DataObject.first.id rescue 0
        max_id = DataObject.last.id rescue 0
        return if max_id == 0
        limit = 500
        i = start
        objects_to_send = []
        while i <= max_id
          objects_to_send = []
          objects_to_send += lookup_data_objects(i, limit);
          unless objects_to_send.blank?
            solr_api.create(objects_to_send)
          end
          i += limit
        end
      end

      def self.remove_data_object(data_object)
        api = SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE)
        api.delete_by_query("data_object_id:#{data_object.id}")
      end

      def self.lookup_data_objects(start, limit)
        max = start + limit # TODO - pretty sure this is a fencepost error (should be -1), but don't care enough...
        objects_to_send = []
        data_objects = DataObject.where("id BETWEEN #{start} AND #{max}")
        self.preload_associations!(data_objects)
        data_objects.each do |d|
          hash = self.solr_schema_data_hash(d)
          objects_to_send << hash
        end
        objects_to_send
      end

      def self.preload_associations!(data_objects)
        DataObject.preload_associations(data_objects,
          [ :data_objects_table_of_contents, :harvest_events, :worklist_ignored_data_objects,
            :curated_data_objects_hierarchy_entries,
            { :data_objects_hierarchy_entries => [ { :vetted => :translations }, { :visibility => :translations },
              { :hierarchy_entry => { :taxon_concept =>
                [ :flattened_ancestors, { :published_hierarchy_entries => :flattened_ancestors } ] } } ] },
            :hierarchy_entries,
            :users_data_object, :data_object_translation, :curator_activity_logs,
            { :data_type => :translations } ])
      end

      def self.reindex_single_object(data_object)
        begin
          solr_connection = self.connect
          solr_connection.delete_by_id(data_object.id)
          solr_connection.create(solr_schema_data_hash(data_object))
          return true
        rescue
        end
        return false
      end

      def self.solr_schema_data_hash(data_object)
        hash = {
          'data_object_id' => data_object.id,
          'guid' => data_object.guid,
          'data_type_id' => data_object.data_type_id,
          'data_subtype_id' => data_object.data_subtype_id || 0,
          'published' => data_object.published? ? 1 : 0,
          'data_rating' => data_object.data_rating,
          'language_id' => data_object.language_id || 0,
          'license_id' => data_object.license_id,
          'created_at' => data_object.created_at ? data_object.created_at.solr_timestamp : '1960-01-01T00:00:01Z'
        }
        # add resource ID
        if he = data_object.harvest_events.first
          hash['resource_id'] = he.resource_id
        end
        # add toc IDs
        data_object.data_objects_table_of_contents.each do |dotoc|
          hash['toc_id'] ||= []
          hash['toc_id'] << dotoc.toc_id
        end
        # add link type IDs
        if data_object.is_link? && link_type_id = data_object.link_type.id
          hash['link_type_id'] = link_type_id
        end
        # add translation_flag
        if data_object.translated_from
          hash['is_translation'] = true
        end

        # add ignored users
        data_object.worklist_ignored_data_objects.each do |ido|
          hash['ignored_by_user_id'] ||= []
          hash['ignored_by_user_id'] << ido.user_id
        end
        # add curated users
        curation = data_object.curator_activity_logs.select{ |cal|
          [ Activity.untrusted.id, Activity.trusted.id, Activity.hide.id, Activity.show.id,
            Activity.inappropriate.id, Activity.unreviewed.id,  Activity.add_association.id,
            Activity.add_common_name.id].include?(cal.activity_id) }
        curation.each do |cal|
          hash['curated_by_user_id'] ||= []
          hash['curated_by_user_id'] << cal.user_id
        end
        # add concepts and ancestors
        data_object.data_object_taxa.each do |assoc|
          field_prefixes = []
          if assoc.vetted
            vetted_label = assoc.vetted.label('en').downcase rescue nil
            vetted_label = 'unreviewed' if vetted_label == 'unknown'
            field_prefixes << vetted_label if ['trusted', 'unreviewed', 'untrusted', 'inappropriate'].include?(vetted_label)
          end
          if assoc.visibility
            visibility_label = assoc.visibility.label('en').downcase rescue nil
            field_prefixes << visibility_label if ['invisible', 'visible', 'preview'].include?(visibility_label)
          end
          hash['taxon_concept_id'] ||= []
          hash['taxon_concept_id'] << assoc.taxon_concept_id
          hash['ancestor_id'] ||= []
          hash['ancestor_id'] << assoc.taxon_concept_id
          if assoc.users_data_object?
            hash['added_by_user_id'] = assoc.user_id
          end
          field_prefixes.each do |prefix|
            hash[prefix + '_taxon_concept_id'] ||= []
            hash[prefix + '_taxon_concept_id'] << assoc.taxon_concept_id
            hash[prefix + '_ancestor_id'] ||= []
            hash[prefix + '_ancestor_id'] << assoc.taxon_concept_id
          end

          # TC ancestors
          if assoc.taxon_concept # sometimes in specs there isn't a concept for an entry...
            ancestor_tc_ids = []
            ancestor_tc_ids += assoc.taxon_concept.flattened_ancestors.collect(&:ancestor_id).sort.uniq

            ancestor_tc_ids.uniq.each do |tc_id|
              hash['ancestor_id'] ||= []
              hash['ancestor_id'] << tc_id
              field_prefixes.each do |prefix|
                hash[prefix + '_ancestor_id'] ||= []
                hash[prefix + '_ancestor_id'] << tc_id
              end
            end
          end
        end
        # clean up and use unique values
        hash.each do |k, v|
          if v.class == Array
            v.delete(0)
            v.uniq!
            v.compact!
          end
        end

        if hash['trusted_ancestor_id']
          hash['max_vetted_weight'] = 5
        elsif hash['unreviewed_ancestor_id']
          hash['max_vetted_weight'] = 4
        elsif hash['untrusted_ancestor_id']
          hash['max_vetted_weight'] = 3
        elsif hash['inappropriate_ancestor_id']
          hash['max_vetted_weight'] = 2
        else
          hash['max_vetted_weight'] = 1
        end

        if hash['visible_ancestor_id']
          hash['max_visibility_weight'] = 4
        elsif hash['invisible_ancestor_id']
          hash['max_visibility_weight'] = 3
        elsif hash['preview_ancestor_id']
          hash['max_visibility_weight'] = 2
        else
          hash['max_visibility_weight'] = 1
        end
        return hash
      end
    end
  end
end
