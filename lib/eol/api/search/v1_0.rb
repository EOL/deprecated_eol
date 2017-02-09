module EOL
  module Api
    module Search
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = Proc.new { I18n.t(:search_method_description) }
        DESCRIPTION = Proc.new { I18n.t('the_xml_search_response_implements',
          :link => view_context.link_to('http://www.opensearch.org/Specifications/OpenSearch/1.1', 'http://www.opensearch.org/Specifications/OpenSearch/1.1')) +
          '</p><p>' + I18n.t('given_the_vast_number') }
        PARAMETERS = Proc.new {
          [
            EOL::Api::DocumentationParameter.new(
              :name => 'q',
              :type => String,
              :required => true,
              :test_value => 'Ursus',
              :notes => I18n.t('the_query_string') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'page',
              :type => Integer,
              :default => 1,
              :required => true,
              :notes => I18n.t('a_maximum_of_30_results_are_returned') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'exact',
              :type => 'Boolean',
              :notes => I18n.t('will_find_taxon_pages_matching_the_search_term') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'filter_by_taxon_concept_id',
              :type => Integer,
              :notes => I18n.t('provide_a_concept_id') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'filter_by_hierarchy_entry_id',
              :type => Integer,
              :notes => I18n.t('provide_a_hierarchy_entry_id') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'filter_by_string',
              :type => String,
              :notes => I18n.t('provide_a_search_string') ),
            EOL::Api::DocumentationParameter.new(
              :name => 'cache_ttl',
              :type => Integer,
              :notes => I18n.t('api_cache_time_to_live_parameter'))
          ] }

        def self.call(params={})
          params[:q] ||= params[:id]
          # ID is used later when logging API requests
          params[:id] = params[:q]
          validate_and_normalize_input_parameters!(params)
          @per_page = 30

          # we had a bunch of searches like "link:QLlHJCZzx" which were throwing errors
          if params[:q].match(/^link:[a-z]+$/i)
            raise EOL::Exceptions::ApiException.new("Invalid search term: \"#{params[:q]}\"")
          end
          prepare_hash(params)
        end

        def self.prepare_hash(params={})
          if params[:q] =~ /^".*"$/
            params[:q] = params[:q][1...-1]
            params[:exact] = true
          end
          @solr = SolrCore::SiteSearch.new
          query = params[:q].gsub(/"/, "\\\"")
          query.fix_spaces
          query = if params[:exact]
            "keyword_exact:\"#{query}\"^5"
          else
            "(keyword_exact:\"#{query}\"^5 OR "\
              "#{EOL::Solr::SiteSearch.keyword_field_for_term(query)}:\"#{query}\"~10^2)"
          end
          if params[:filter_by_string]
            id = @solr.named_taxon_id(params[:filter_by_string])
            query += " AND (ancestor_taxon_concept_id:#{id})" if id
          elsif id = params[:filter_by_taxon_concept_id]
            query += " AND (ancestor_taxon_concept_id:#{id})"
          elsif params[:filter_by_hierarchy_entry_id]
            id = HierarchyEntry.where(id: params[:filter_by_hierarchy_entry_id]).
              pluck(:taxon_concept_id).first
            query += " AND (ancestor_taxon_concept_id:#{id})"
          end
          query += " AND _val_:richness_score^200"
          response = @solr.taxa(query, params[:page], @per_page)
          results = []
          response["docs"].each do |result|
            result_hash = {}
            result_hash['id'] = result['resource_id']
            result_hash['title'] = result['instance'].title.strip_italics
            result_hash['link'] = url_for(:controller => 'taxa', :action => 'overview', :id => result['resource_id'], :only_path => false)
            result_hash['content'] = result['keyword'].join('; ')
            results << result_hash
          end
          last_page = (response["numFound"] / @per_page.to_f).ceil
          search_api_url = url_for(:controller => 'api', :action => 'search', :id => params[:q], :format => params[:format], :only_path => false)
          return_hash = {}
          return_hash['totalResults'] = response["numFound"]
          return_hash['startIndex']   = ((params[:page]) * @per_page) - @per_page + 1
          return_hash['itemsPerPage'] = @per_page
          return_hash['results']      = results
          return_hash['first']        = "#{search_api_url}?page=1" if params[:page] <= last_page
          return_hash['previous']     = "#{search_api_url}?page=#{params[:page]-1}" if params[:page] > 1 && params[:page] <= last_page
          return_hash['self']         = "#{search_api_url}?page=#{params[:page]}" if params[:page] <= last_page
          return_hash['next']         = "#{search_api_url}?page=#{params[:page]+1}" if params[:page] < last_page
          return_hash['last']         = "#{search_api_url}?page=#{last_page}" if params[:page] <= last_page
          return_hash
        end
      end
    end
  end
end
