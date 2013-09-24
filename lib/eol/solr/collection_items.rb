# NOTE - Not changing object_id or object_type in this file because we don't want to reindex Solr entirely.
module EOL
  module Solr
    class CollectionItems
      def self.search_with_pagination(collection_id, options = {})
        options[:page]        ||= 1
        options[:per_page]    ||= 50
        options[:per_page]      = 50 if options[:per_page] == 0

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
        instances = CollectionItem.find(ids)
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
        ids = docs.map{ |d| d['object_id'] }
        instances = Community.find(ids)
        docs.map! do |d|
          unless d['instance'].nil?
            d['instance'].collected_item = instances.detect{ |i| i.id == d['object_id'].to_i }
          end
        end
      end

      def self.add_collection!(docs, options = {})
        return if docs.empty?
        ids = docs.map{ |d| d['object_id'] }
        instances = Collection.find(ids)
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
        ids = docs.map{ |d| d['object_id'] }
        instances = User.find(ids)
        docs.map! do |d|
          unless d['instance'].nil?
            d['instance'].collected_item = instances.detect{ |i| i.id == d['object_id'].to_i }
          end
        end
      end

      def self.add_taxon_concept!(docs, options = {})
        return if docs.empty?
        includes = [ { :preferred_entry => 
          { :hierarchy_entry => [ { :name => [ :canonical_form, :ranked_canonical_form ] } , :hierarchy, :vetted ] } },
          :taxon_concept_metric ]
        selects = {
          :taxon_concepts => '*',
          :taxon_concept_preferred_entries => '*',
          :taxon_concept_exemplar_images => '*',
          :taxon_concept_metrics => [ :taxon_concept_id, :richness_score ],
          :hierarchy_entries => [ :id, :rank_id, :name_id, :identifier, :hierarchy_id, :parent_id, :published, :vetted_id, :visibility_id, :lft, :rgt, :taxon_concept_id, :source_url ],
          :names => [ :id, :string, :italicized, :canonical_form_id, :ranked_canonical_form_id ],
          :canonical_forms => [ :id, :string ],
          :hierarchies => [ :id, :agent_id, :browsable, :outlink_uri, :label ],
          :vetted => [ :id, :view_order ],
          :hierarchy_entries_flattened => '*',
          :ranks => '*',
          :data_objects => [ :id, :object_cache_url, :data_type_id, :guid, :published, :language_id ]
        }
        if options[:view_style] == ViewStyle.annotated
          includes << { :preferred_common_names => [ :name, :language ] }
          includes << { :preferred_entry => 
            { :hierarchy_entry => [
              { :name => [ :canonical_form, :ranked_canonical_form ] } , :hierarchy, :vetted ] } }
          includes << { :taxon_concept_exemplar_image => :data_object }
        end
        ids = docs.map{ |d| d['object_id'] }
        instances = TaxonConcept.find(ids)
        TaxonConcept.preload_associations(instances, includes, :select => selects)
        docs.each do |d|
          if d['instance']
            d['instance'].collected_item = instances.detect{ |i| i.id == d['object_id'].to_i }
          end
        end
      end

      def self.add_data_object!(docs, options = {})
        return if docs.empty?
        ids = docs.map{ |d| d['object_id'] }
        instances = DataObject.find(ids)
        DataObject.preload_associations(instances, [ :language, :all_published_versions ] )
        instances_that_are_used = []
        docs.each do |d|
          if i = instances.detect{ |i| i.id == d['object_id'].to_i }
            if d['instance'] 
              if latest_version = i.latest_published_version_in_same_language
                d['instance'].collected_item = latest_version
              else
                d['instance'].collected_item = i
              end
              d['instance'].collected_item.is_the_latest_published_revision = true
              instances_that_are_used << d['instance'].collected_item
            end
          end
        end
        
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
          :hierarchy_entries => [ :id, :published, :vetted_id, :visibility_id, :taxon_concept_id, :name_id, :hierarchy_id ],
          :names => [ :id, :string, :canonical_form_id, :ranked_canonical_form_id ],
          :canonical_forms => [ :id, :string ],
          :languages => '*'
        }
        
        if options[:view_style] == ViewStyle.annotated
          includes << { :data_objects_hierarchy_entries => [ { :hierarchy_entry => [ { :name => [ :canonical_form, :ranked_canonical_form ] }, :hierarchy ] },
            :vetted, :visibility ] }
          includes << { :curated_data_objects_hierarchy_entries => [ :user, { :hierarchy_entry => [ { :name => [ :canonical_form, :ranked_canonical_form ] }, :hierarchy ] } ] }
          includes << { :all_curated_data_objects_hierarchy_entries => [ :user, { :hierarchy_entry => [ { :name => [ :canonical_form, :ranked_canonical_form ] }, :hierarchy ] } ] }
        end
        DataObject.preload_associations(instances_that_are_used, includes, :select => selects)
        if options[:view_style] == ViewStyle.annotated
          HierarchyEntry.preload_associations(instances_that_are_used.collect{ |d| d.first_hierarchy_entry }, [ { :name => [ :canonical_form, :ranked_canonical_form ] }, :hierarchy ] )
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
