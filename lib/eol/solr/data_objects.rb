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
        options[:vetted_type] ||= 'trusted'
        options[:visibility_type] ||= 'visible'
        options[:sort_by] ||= 'data_object_id+desc'
        
        url =  $SOLR_SERVER + $SOLR_DATA_OBJECTS_CORE + '/select/?wt=json&q=' + CGI.escape('{!lucene}')
        url << CGI.escape("#{options[:vetted_type]}_ancestor_id:#{taxon_concept_id} AND ")
        url << CGI.escape("#{options[:visibility_type]}_ancestor_id:#{taxon_concept_id} AND published:1")
        if options[:data_type_ids]
          url << CGI.escape(" AND (data_type_id:#{options[:data_type_ids].join(' OR data_type_id:')})")
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
      
    end
  end
end
