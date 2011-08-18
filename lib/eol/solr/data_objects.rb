module EOL
  module Solr
    class DataObjects

      def self.search_with_pagination(taxon_concept_id, options = {})
        options[:page]        ||= 1
        options[:per_page]    ||= 30
        options[:per_page]      = 30 if options[:per_page] == 0

        response = solr_search(taxon_concept_id, options)
        total_results = response['response']['numFound']
        results = response['response']['docs']
        add_resource_instances!(results)

        results = WillPaginate::Collection.create(options[:page], options[:per_page], total_results) do |pager|
          pager.replace(results.collect{ |r| r['instance'] }.compact)
        end
        results
      end

      def self.add_resource_instances!(docs)
        EOL::Solr.add_standard_instance_to_docs!(DataObject, docs, 'data_object_id',
          :includes => [ :hierarchy_entries ],
          :selects => { :data_objects => '*', :hierarchy_entries => '*' })
      end

      def self.solr_search(taxon_concept_id, options = {})
        url =  $SOLR_SERVER + $SOLR_DATA_OBJECTS_CORE + '/select/?wt=json&q=' + CGI.escape("{!lucene}published:1 AND ancestor_id:#{taxon_concept_id}")
        if options[:filter_hierarchy_entry] && options[:filter_hierarchy_entry].class == HierarchyEntry
          field_suffix = "ancestor_he_id"
          search_id = options[:filter_hierarchy_entry].id
          url << CGI.escape(" AND ancestor_he_id:#{search_id}")
        else
          field_suffix = "ancestor_id"
          search_id = taxon_concept_id
        end

        if options[:vetted_types] && !options[:vetted_types].include?('all')
          url << CGI.escape(" AND (")
          url << CGI.escape(options[:vetted_types].collect{ |t| "#{t}_#{field_suffix}:#{search_id}" }.join(' OR '))
          url << CGI.escape(")")
        end
        if options[:visibility_types] && !options[:visibility_types].include?('all')
          url << CGI.escape(" AND (")
          url << CGI.escape(options[:visibility_types].collect{ |t| "#{t}_#{field_suffix}:#{search_id}" }.join(' OR '))
          url << CGI.escape(")")
        end

        if options[:data_type_ids]
          url << CGI.escape(" AND (data_type_id:#{options[:data_type_ids].join(' OR data_type_id:')})")
        else
          url << CGI.escape(" NOT (data_type_id:#{DataType.iucn.id})")
        end
        # filter
        if options[:filter] == 'curated' && options[:user]
          url << CGI.escape(" AND curated_by_user_id:#{options[:user].id}")
        elsif options[:filter] == 'ignored' && options[:user]
          url << CGI.escape(" AND ignored_by_user_id:#{options[:user].id}")
        elsif options[:filter] == 'active'
          url << CGI.escape(" NOT curated_by_user_id:#{options[:user].id} NOT ignored_by_user_id:#{options[:user].id}")
        end

        if options[:ignore_maps]
          url << CGI.escape(" NOT data_subtype_id:#{DataType.map.id}")
        end

        # add sorting
        if options[:sort_by] == 'newest'
          url << '&sort=data_object_id+desc'
        elsif options[:sort_by] == 'oldest'
          url << '&sort=data_object_id+asc'
        elsif options[:sort_by] == 'status'
          url << '&sort=max_visibility_weight+desc,max_vetted_weight+desc,data_rating+desc'
        else
          url << '&sort=data_rating+desc'
        end
        # we only need a couple fields
        url << "&fl=data_object_id,guid"
        # add paging
        limit  = options[:per_page] ? options[:per_page].to_i : 10
        page = options[:page] ? options[:page].to_i : 1
        offset = (page - 1) * limit
        url << '&start=' << URI.encode(offset.to_s)
        url << '&rows='  << URI.encode(limit.to_s)
        res = open(url).read
        JSON.load res
      end

      def self.get_facet_counts(taxon_concept_id)
        facets = {}
        base_url =  $SOLR_SERVER + $SOLR_DATA_OBJECTS_CORE + '/select/?wt=json&q=' + CGI.escape(%Q[{!lucene}])
        [true, false].each do |do_ancestor|
          ['trusted', 'unreviewed'].each do |vetted_status|
            url = base_url.dup + CGI.escape(%Q[#{vetted_status}_ancestor_id:#{taxon_concept_id} AND visible_ancestor_id:#{taxon_concept_id}])
            url << CGI.escape(" AND taxon_concept_id:#{taxon_concept_id}") unless do_ancestor
            url << '&facet.field=data_type_id&facet=on&rows=0'
            res = open(url).read
            response = JSON.load(res)
            f = response['facet_counts']['facet_fields']['data_type_id']
            key_prefix = vetted_status
            key_prefix = "ancestor_" + key_prefix if do_ancestor
            f.each_with_index do |rt, index|
              next if index % 2 == 1 # if its odd, skip this. Solr has a strange way of returning the facets in JSON
              data_type = DataType.find(rt.to_i)
              key = key_prefix + "_" + data_type.label('en').downcase
              facets[key] = f[index+1]
            end
            facets[key_prefix + "_video"] ||= 0
            facets[key_prefix + "_video"] += facets[key_prefix + "_youtube"] if facets[key_prefix + "_youtube"]
            facets[key_prefix + "_video"] += facets[key_prefix + "_flash"] if facets[key_prefix + "_flash"]
          end
        end
        facets
      end

      def self.reindex_single_object(data_object)
        hash = {
          'data_object_id' => data_object.id,
          'guid' => data_object.guid,
          'data_type_id' => data_object.data_type_id,
          'data_subtype_id' => data_object.data_subtype_id || 0,
          'published' => data_object.published? ? 1 : 0,
          'data_rating' => data_object.data_rating,
          # 'language_id' => data_object.language_id,
          # 'license_id' => data_object.license_id,
          'created_at' => data_object.created_at ? data_object.created_at.solr_timestamp : nil
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
        curation = CuratorActivityLog.find_all_by_object_id_and_changeable_object_type_id_and_activity_id(data_object.id,
          [ ChangeableObjectType.data_object.id, ChangeableObjectType.data_objects_hierarchy_entry.id ],
          [ Activity.untrusted.id, Activity.trusted.id, Activity.untrusted.id, Activity.hide.id, Activity.show.id,
            Activity.inappropriate.id, Activity.unreviewed.id,  Activity.add_association.id,  Activity.add_common_name.id])
        curation.each do |cal|
          hash['curated_by_user_id'] ||= []
          hash['curated_by_user_id'] << cal.user_id
        end
        # add concepts and ancestors
        (data_object.hierarchy_entries + data_object.curated_hierarchy_entries + [data_object.users_data_object]).compact.each do |he|
          field_prefixes = []
          if he.vetted
            vetted_label = he.vetted.label('en').downcase rescue nil
            vetted_label = 'unreviewed' if vetted_label == 'unknown'
            field_prefixes << vetted_label if ['trusted', 'unreviewed', 'untrusted', 'inappropriate'].include?(vetted_label)
          end
          if he.visibility
            visibility_label = he.visibility.label('en').downcase rescue nil
            field_prefixes << visibility_label if ['invisible', 'visible', 'preview'].include?(visibility_label)
          end
          hash['taxon_concept_id'] ||= []
          hash['taxon_concept_id'] << he.taxon_concept_id
          hash['ancestor_id'] ||= []
          hash['ancestor_id'] << he.taxon_concept_id
          if he.class == UsersDataObject
            hash['added_by_user_id'] = he.user_id
          else
            hash['hierarchy_entry_id'] ||= []
            hash['hierarchy_entry_id'] << he.id
          end
          field_prefixes.each do |prefix|
            hash[prefix + '_ancestor_id'] ||= []
            hash[prefix + '_ancestor_id'] << he.taxon_concept_id
          end
          # TC ancestors
          he.taxon_concept.flattened_ancestors.each do |a|
            hash['ancestor_id'] ||= []
            hash['ancestor_id'] << a.ancestor_id
            field_prefixes.each do |prefix|
              hash[prefix + '_ancestor_id'] ||= []
              hash[prefix + '_ancestor_id'] << a.ancestor_id
            end
          end
          # HE ancestors
          TaxonConcept.preload_associations(he.taxon_concept, { :published_hierarchy_entries => :flattened_ancestors })
          he.taxon_concept.published_hierarchy_entries.each do |tche|
            hash['ancestor_he_id'] ||= []
            hash['ancestor_he_id'] << tche.id
            field_prefixes.each do |prefix|
              hash[prefix + '_ancestor_he_id'] ||= []
              hash[prefix + '_ancestor_he_id'] << tche.id
            end

            tche.flattened_ancestors.each do |a|
              hash['ancestor_he_id'] ||= []
              hash['ancestor_he_id'] << a.ancestor_id
              field_prefixes.each do |prefix|
                hash[prefix + '_ancestor_he_id'] ||= []
                hash[prefix + '_ancestor_he_id'] << a.ancestor_id
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

        begin
          solr_connection = SolrAPI.new($SOLR_SERVER, $SOLR_DATA_OBJECTS_CORE)
          solr_connection.delete_by_id(data_object.id)
          solr_connection.create(hash)
          return true
        rescue
        end
        return false
      end

    end
  end
end
