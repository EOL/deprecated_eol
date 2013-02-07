module EOL
  module Solr
    class BHL
      def self.search(taxon_concept, options = {})
        options[:page]        ||= 1
        options[:per_page]    ||= 100
        options[:per_page]      = 10 if options[:per_page] == 0
        
        response = solr_search(taxon_concept, options)
        
        total_results = response['grouped']['title_item_id']['ngroups']
        query_time = response['responseHeader']['QTime']
        return_hash = { :time => query_time,
                        :total => total_results }
        
        return_hash[:results] = []
        response['grouped']['title_item_id']['groups'].each do |g|
          doc = g['doclist']['docs'][0].merge({ 'numFound' => g['doclist']['numFound'] })
          return_hash[:results] << doc
        end
        
        return_hash[:results] = WillPaginate::Collection.create(options[:page], options[:per_page], total_results) do |pager|
           pager.replace(return_hash[:results])
        end
        
        return return_hash
      end
      
      def self.search_publication(taxon_concept, title_item_id, options = {})
        options[:page]        ||= 1
        options[:per_page]    ||= 500
        options[:per_page]      = 10 if options[:per_page] == 0
        options[:sort] = 'number'
        response = solr_search(taxon_concept, options.merge({ :title_item_id => title_item_id }))
        query_time = response['responseHeader']['QTime']
        total_results = response['response']['numFound']
        return_hash = { :time => query_time,
                        :total => total_results,
                        :results => response['response']['docs'] }
        return return_hash
      end
      
      private
      
      def self.solr_search(taxon_concept, options = {})
        
        url =  $SOLR_SERVER + $SOLR_BHL_CORE + '/select/?wt=json&q=' + CGI.escape(%Q[{!lucene}])
        name_ids = TaxonConceptName.connection.select_values("SELECT DISTINCT(name_id) FROM taxon_concept_names WHERE taxon_concept_id=#{taxon_concept.id} AND vern=0 LIMIT 100")
        name_ids = [0] if name_ids.blank?
        url << CGI.escape("(name_id:(#{name_ids.join(' ')}) NOT year:0)")
        if options[:title_item_id]
          url << CGI.escape(" AND title_item_id:#{options[:title_item_id]}")
        end
        # add sort
        if options[:sort] == 'number'
          url << '&sort=' + CGI.escape("number asc")
        elsif options[:sort] == 'title'
          url << '&sort=' + CGI.escape("publication_title asc, volume asc, year asc")
        elsif options[:sort] == 'title_desc'
          url << '&sort=' + CGI.escape("publication_title desc, volume asc, year asc")
        elsif options[:sort] == 'year_desc'
          url << '&sort=' + CGI.escape("year desc, publication_title asc, volume desc")
        else # year
          url << '&sort=' + CGI.escape("year asc, publication_title asc, volume asc")
        end
        # add group by publication
        unless options[:title_item_id]
          url << "&group=true&group.ngroups=true&group.field=title_item_id"
        end
        # return fields
        url << '&fl=id,publication_title,publication_id,title_item_id,details,year,start_year,end_year,volume,issue,number,prefix,volume_info'
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
