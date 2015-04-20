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
          # find a visible match, get the published ones first
          hierarchy_entries = HierarchyEntry.find_all_by_hierarchy_id_and_identifier(params[:hierarchy_id], params[:id],
            :joins => 'JOIN taxon_concepts tc ON (hierarchy_entries.taxon_concept_id=tc.id)',
            :conditions => "hierarchy_entries.visibility_id = #{Visibility.get_visible.id} AND tc.published=1", :order => '(hierarchy_entries.published=1) desc')
          prepare_hash(hierarchy_entries, params)
        end

        def self.prepare_hash(hierarchy_entries, params={})
          return_hash = []
          hierarchy_entries.each do |r|
            return_hash << { 'eol_page_id' => r.taxon_concept_id }
          end
          return return_hash
        end
      end
    end
  end
end
