module EOL
  module Solr
    class BHL
      def self.search(taxon_concept, options = {})
        options[:page]        ||= 1
        options[:per_page]    ||= 300
        options[:per_page]      = 10 if options[:per_page] == 0
        
        response = solr_search(taxon_concept, options)
        return response
      end

      private
      
      def self.solr_search(taxon_concept, options = {})
        url =  $SOLR_SERVER + $SOLR_BHL_CORE + '/select/?wt=json&fl=publication_title,details&q=' + CGI.escape(%Q[{!lucene}])
        
        
        server_url = $SOLR_SERVER
        core = $SOLR_BHL_CORE
        server_url += '/' unless server_url[-1,1] == '/'
        action_url = server_url + core.to_s
        # this one should NOT end in a slash
        action_url = action_url[0...-1] if action_url[-1,1] == '/'
        action_uri = URI.parse(action_url)
        
        name_ids = TaxonConceptName.find_all_by_taxon_concept_id_and_vern(taxon_concept, 0, :select => 'name_id').collect{|tcn| tcn.name_id}.uniq.sort
        name_ids = name_ids[0..400]
        
        # post_url = action_url + "/select"
        # request = Net::HTTP::Post.new(post_url)
        # request.set_form_data({"wt" => "json", "q" => "name_id:(#{name_ids.join(' ')})"})
        # response = Net::HTTP.start(action_uri.host, action_uri.port) do |http|
        #   http.open_timeout = 30
        #   http.read_timeout = 240
        #   http.request(request)
        # end
        # rescue Timeout::Error => e
        #   puts "Timeout accessing #{post_url}"
        #   pp e.message
        #   pp e.backtrace
        #   nil
        # rescue => e
        #   puts "Error accessing #{post_url}"
        #   pp e.message
        #   pp e.backtrace
        #   nil
        # 
        # return
        
        url << CGI.escape("name_id:(#{name_ids.join(' ')})")
        
        # # add sorting
        # if options[:sort_by] == SortStyle.newest
          url << '&sort=' + CGI.escape("year asc, start_year asc, publication_title asc, number asc")
        # elsif options[:sort_by] == SortStyle.oldest
        #   url << '&sort=date_modified+asc'
        # end
        
        url << '&fl=' + CGI.escape("publication_title, details, year, start_year, end_year, volume, issue, number, prefix");
        
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
