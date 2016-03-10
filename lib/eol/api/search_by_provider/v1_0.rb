module EOL
  module Api
    module SearchByProvider
      class V1_0 < EOL::Api::MethodVersion
        VERSION = '1.0'
        BRIEF_DESCRIPTION = Proc.new {
          if Hierarchy.itis
            test_entry = HierarchyEntry.where("hierarchy_id = #{Hierarchy.itis.id} AND identifier = '180542' AND published = 1").first
          else
            test_entry = HierarchyEntry.where("published = 1 AND identifier != '' AND identifier IS NOT NULL").last
          end
          url = url_for(:controller => '/api', :action => 'search_by_provider', :version => '1.0', :id => test_entry.identifier, :hierarchy_id => test_entry.hierarchy_id, :only_path => false)
          I18n.t(:search_by_provider_method_description_with_link, :link => view_context.link_to(url, url))
        }
        DESCRIPTION = Proc.new {
          test_hierarchy = (Hierarchy.itis || HierarchyEntry.where("published = 1 AND identifier != '' AND identifier IS NOT NULL").last.hierarchy)
          provider_hierarchies_url = url_for(:controller => '/api/docs', :action => 'provider_hierarchies')
          search_by_provider_url = url_for(:controller => '/api', :action => 'search_by_provider', :version => '1.0', :id => '180542', :hierarchy_id => test_hierarchy.id, :only_path => false)
          I18n.t("this_method_takes_an_integer_or_string",
            :link_provider => view_context.link_to('provider_hierarchies', provider_hierarchies_url),
            :link_url => view_context.link_to(search_by_provider_url, search_by_provider_url),
            :itis_id => test_hierarchy.id)
        }
        PARAMETERS = Proc.new {
          [ 
            EOL::Api::DocumentationParameter.new(
              :name => 'batch',
              :type => 'Boolean',
              :required => false,
              :default => false,
              :test_value => false,
              :notes => I18n.t('returns_either_a_batch_or_not')),
            EOL::Api::DocumentationParameter.new(
              :name => 'id',
              :type => String,
              :required => true,
              :test_value => 180542 ),
            EOL::Api::DocumentationParameter.new(
              :name => 'hierarchy_id',
              :type => Integer,
              :required => true,
              :test_value => (Hierarchy.itis || HierarchyEntry.where("published = 1 AND identifier != '' AND identifier IS NOT NULL").last.hierarchy).id,
              :notes => I18n.t("the_id_of_provider_hierarchy_you_are_searching", :link => view_context.link_to('provider_hierarchies', url_for(:controller => 'api/docs', :action => 'provider_hierarchies'))) ),
            EOL::Api::DocumentationParameter.new(
              :name => 'cache_ttl',
              :type => Integer,
              :notes => I18n.t('api_cache_time_to_live_parameter'))
          ] }

        def self.call(params={})
          validate_and_normalize_input_parameters!(params)
          results = []
          if params[:batch]
            identifiers = params[:id].split(',')
            identifiers.each do |id|
              results << { id => get_taxon_concept_ids(id, params[:hierarchy_id]) }
            end
          else
            results = get_taxon_concept_ids(params[:id], params[:hierarchy_id])
          end
           prepare_hash(results, params)
        end

        def self.prepare_hash(results, params={})
          return_hash = []
          unless params[:batch]
            results.compact.each do |tc_id|
              return_hash << { 'eol_page_id' => tc_id }
               return_hash << { 'eol_page_link' => "#{Rails.configuration.site_domain}/pages/#{tc_id}" }
            end
            return return_hash
          else
            results.each do |result|
              result_array =[]
              result.each do |id, tc_ids|
                tc_ids.compact.each do |tc_id|
                 result_array << { 'eol_page_id' => tc_id}
                 result_array << { 'eol_page_link' => "#{Rails.configuration.site_domain}/pages/#{tc_id}" }
                end
                return_hash << { id => result_array } unless result_array.blank?
              end
            end
            return return_hash
          end
        end

        def self.get_taxon_concept_ids(identifier, hierarchy_id)
          hierarchy_entries = HierarchyEntry.includes(:taxon_concept).where(hierarchy_id: hierarchy_id, identifier: identifier, visibility_id: Visibility.get_visible.id, published: true)
           debugger 
          hierarchy_entries_ids = hierarchy_entries.map{ |h| h.taxon_concept_id if h.taxon_concept.published? }

          synonyms = Synonym.includes(hierarchy_entry: :taxon_concept).
           where(hierarchy_id: hierarchy_id, identifier: identifier)
          synonyms_ids = synonyms.map{ |s| s.taxon_concept.id if s.taxon_concept.published? }

          return (hierarchy_entries_ids + synonyms_ids).uniq
        end
      end
    end
  end
end
