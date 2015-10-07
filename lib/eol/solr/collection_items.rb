# NOTE - Not changing object_id or object_type in this file because we don't want to reindex Solr entirely.
module EOL
  module Solr
    class CollectionItems
      def self.search_with_pagination(collection_id, options = {})
        options[:page]        ||= 1
        options[:per_page]    ||= 40
        options[:per_page]      = 40 if options[:per_page] == 0

        response = solr_search(collection_id, options)
        total_results = response['response']['numFound']
        results = response['response']['docs']
        add_resource_instances!(results, options)

        results = WillPaginate::Collection.create(options[:page], options[:per_page], total_results) do |pager|
          pager.replace(results)
        end
        results
      end

      private

      def self.add_resource_instances!(docs, options = {})
        return if docs.empty?
        ids = docs.map{ |d| d['collection_item_id'] }
        instances = CollectionItem.where(id: ids)
        if options[:view_style] == ViewStyle.annotated
          CollectionItem.preload_associations(instances, :refs, :select =>
            { :refs => [ :id, :full_reference ] } )
        end
        return if ids.empty?
        raise "No CollectionItem instances found from IDs #{ids.join(', ')}.  Rebuild indexes." if instances.empty?
        docs.each do |d|
          d['instance'] = instances.detect{ |i| i.id == d['collection_item_id'].to_i }
        end

        add_community!(docs.select{ |d| d['object_type'] == 'Community' }, options)
        add_collection!(docs.select{ |d| d['object_type'] == 'Collection' }, options)
        add_user!(docs.select{ |d| d['object_type'] == 'User' || d['object_type'] == 'Curator' }, options)
        add_taxon_concept!(docs.select{ |d| d['object_type'] == 'TaxonConcept' }, options)
        add_data_object!(docs.select{ |d| ['Image', 'Video', 'Sound', 'Text', 'DataObject', 'Link', 'Map'].include? d['object_type'] }, options)
      end

      def self.add_community!(docs, options = {})
        return if docs.empty?
        instances = Community.where(id: docs.map{ |d| d['object_id'] })
        docs.map! do |d|
          unless d['instance'].nil?
            d['instance'].collected_item = instances.detect{ |i| i.id == d['object_id'].to_i }
          end
        end
      end

      def self.add_collection!(docs, options = {})
        return if docs.empty?
        instances = Collection.where(id: docs.map{ |d| d['object_id'] })
        if options[:view_style] == ViewStyle.annotated
          Collection.preload_associations(instances, [ :users, :communities ], :select =>
            { :users => '*', :communities => '*' } )
        end
        docs.map! do |d|
          unless d['instance'].nil?
            d['instance'].collected_item = instances.detect{ |i| i.id == d['object_id'].to_i }
          end
        end
      end

      def self.add_user!(docs, options = {})
        return if docs.empty?
        instances = User.where(id: docs.map{ |d| d['object_id'] })
        docs.map! do |d|
          unless d['instance'].nil?
            d['instance'].collected_item = instances.detect{ |i| i.id == d['object_id'].to_i }
          end
        end
      end

      def self.add_taxon_concept!(docs, options = {})
        return if docs.empty?
        instances = TaxonConcept.where(id: docs.map{ |d| d['object_id'] })
        if options[:view_style] == ViewStyle.list
          includes =
          { :preferred_entry =>
            { :hierarchy_entry => [ { :name => :ranked_canonical_form } ] } }
          TaxonConcept.preload_associations(instances, includes)
        else
          TaxonConcept.preload_for_shared_summary(instances, :language_id => options[:language_id],
            :skip_common_names => (options[:view_style] == ViewStyle.gallery),
            :skip_ancestry => (options[:view_style] == ViewStyle.gallery))
        end
        TaxonConcept.preload_associations(instances, :taxon_concept_metric, :select => [ :taxon_concept_id, :richness_score ])
        docs.each do |d|
          if d['instance']
            d['instance'].collected_item = instances.detect{ |i| i.id == d['object_id'].to_i }
          end
        end
      end

      def self.add_data_object!(docs, options = {})
        return if docs.empty?
        instances = DataObject.where(id: docs.map{ |d| d['object_id'] })
        docs.each do |d|
          if d['instance']
            d['instance_guid'] = instances.detect{ |i| i.id == d['object_id'].to_i }.guid
          end
        end
        DataObject.replace_with_latest_versions!(instances, language_id: options[:language_id], check_only_published: true)

        includes = [ { :toc_items => :translations }, :data_type ]
        selects = {
          :data_objects => '*',
          :data_objects_hierarchy_entries => '*',
          :hierarchies => '*',
          :curated_data_objects_hierarchy_entries => '*',
          :table_of_contents => '*',
          :translated_table_of_contents => '*',
          :users => '*',
          :vetted => '*',
          :visibilties => '*',
          :hierarchy_entries => [ :id, :published, :vetted_id, :visibility_id, :taxon_concept_id, :name_id, :hierarchy_id, :rank_id ],
          :names => [ :id, :string, :canonical_form_id, :ranked_canonical_form_id ],
          :canonical_forms => [ :id, :string ],
          :languages => '*'
        }

        includes << { :data_objects_hierarchy_entries => [ { :hierarchy_entry =>
          [ { :name => [ :canonical_form, :ranked_canonical_form ] }, :taxon_concept, :hierarchy ] },
          :vetted, :visibility ] }
        includes << :users_data_object
        includes << { :all_curated_data_objects_hierarchy_entries =>
          [ :user, { :hierarchy_entry => [ { :name => [ :canonical_form, :ranked_canonical_form ] }, :hierarchy ] },
          :vetted, :visibility ] }
        DataObject.preload_associations(instances, includes, :select => selects)
        if options[:view_style] == ViewStyle.annotated
          HierarchyEntry.preload_associations(instances.collect{ |d| d.first_hierarchy_entry }, [ { :name => [ :canonical_form, :ranked_canonical_form ] }, :hierarchy ] )
        end
        docs.each do |d|
          if d['instance_guid']
            d['instance'].collected_item = instances.detect{ |i| i.guid == d['instance_guid'] }
          end
        end
      end

      def self.solr_search(collection_id, options = {})
        url =  $SOLR_SERVER + $SOLR_COLLECTION_ITEMS_CORE + '/select/?wt=json&q=' + CGI.escape(%Q[{!lucene}])
        url << CGI.escape(%Q[(collection_id:#{collection_id})])

        # add links filtering
        if options[:link_type_id] && options[:link_type_id] != 0
          url << CGI.escape(" AND (link_type_id:#{options[:link_type_id]})")
        end

        # add links filtering
        unless options[:sort_field].blank?
          url << CGI.escape(" AND sort_field:\"#{options[:sort_field]}\"")
        end

        # add facet filtering
        if options[:facet_type]
          facet_type = nil
          case options[:facet_type].downcase
          when 'taxa', 'taxonconcept', 'taxon'
            facet_type = 'TaxonConcept'
          when 'articles', 'text'
            facet_type = 'Text'
          when 'videos', 'video'
            facet_type = 'Video'
          when 'images', 'image'
            facet_type = 'Image'
          when 'sounds', 'sound'
            facet_type = 'Sound'
          when 'links', 'link'
            facet_type = 'Link'
          when 'communities', 'community'
            facet_type = 'Community'
          when 'people', 'user'
            facet_type = 'User'
          when 'collections', 'collection'
            facet_type = 'Collection'
          end
          url << "&fq=object_type:#{facet_type}" if facet_type
        end

        # add sorting
        if options[:sort_by] == SortStyle.newest
          url << '&sort=date_modified+desc,collection_item_id+desc'
        elsif options[:sort_by] == SortStyle.oldest
          url << '&sort=date_modified+asc,collection_item_id+asc'
        elsif options[:sort_by] == SortStyle.alphabetical
          url << '&sort=title_exact+asc,collection_item_id+asc'
        elsif options[:sort_by] == SortStyle.reverse_alphabetical
          url << '&sort=title_exact+desc,collection_item_id+desc'
        elsif options[:sort_by] == SortStyle.richness
          url << '&sort=richness_score+desc,collection_item_id+desc'
        elsif options[:sort_by] == SortStyle.rating
          url << '&sort=data_rating+desc,collection_item_id+desc'
        elsif options[:sort_by] == SortStyle.sort_field
          url << '&sort=sort_field+asc,collection_item_id+asc'
        elsif options[:sort_by] == SortStyle.reverse_sort_field
          url << '&sort=sort_field+desc,collection_item_id+desc'
        end

        # add paging
        limit  = options[:per_page] ? options[:per_page].to_i : 10
        page = options[:page] ? options[:page].to_i : 1
        offset = (page - 1) * limit
        url << '&start=' << URI.encode(offset.to_s)
        url << '&rows='  << URI.encode(limit.to_s)
        res = open(url).read
        JSON.load res
      end

      def self.get_facet_counts(collection_id)
        url =  $SOLR_SERVER + $SOLR_COLLECTION_ITEMS_CORE + '/select/?wt=json&q=' + CGI.escape(%Q[{!lucene}])
        url << CGI.escape(%Q[collection_id:#{collection_id}])
        url << '&facet.field=object_type&facet=on&rows=0'
        res = open(url).read
        response = JSON.load(res)

        facets = {}
        f = response['facet_counts']['facet_fields']['object_type']
        f.each_with_index do |rt, index|
          next if index % 2 == 1 # if its odd, skip this. Solr has a strange way of returning the facets in JSON
          facets[rt] = f[index+1]
        end
        total_results = response['response']['numFound']
        facets['All'] = total_results
        facets
      end
    end
  end
end
