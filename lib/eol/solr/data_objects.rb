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
        if options[:vetted_type] && options[:vetted_type] != 'all'
          url << CGI.escape(" AND #{options[:vetted_type]}_ancestor_id:#{taxon_concept_id}")
        end
        if options[:visibility_type] && options[:visibility_type] != 'all'
          url << CGI.escape(" AND #{options[:visibility_type]}_ancestor_id:#{taxon_concept_id}")
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
        else # active
          url << CGI.escape(" NOT curated_by_user_id:#{options[:user].id} NOT ignored_by_user_id:#{options[:user].id}")
        end
        # add sorting
        if options[:sort_by] == 'newest'
          url << '&sort=data_object_id+desc'
        elsif options[:sort_by] == 'oldest'
          url << '&sort=data_object_id+asc'
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
            facets[key_prefix + "_video"] += facets[key_prefix + "_youtube"] if facets[key_prefix + "_youtube"]
            facets[key_prefix + "_flash"] += facets[key_prefix + "_flash"] if facets[key_prefix + "_flash"]
          end
        end
        facets
        
      end
      
    end
  end
end
