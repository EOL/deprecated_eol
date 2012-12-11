class Api::DocsController < ApiController
  layout 'v2/basic'
  before_filter :set_navigation_menu, :set_method_name, :create_documentation_hash

  def index
    @page_title = I18n.t(:eol_api)
  end

  def ping
    @page_title = I18n.t(:eol_api_ping)
    render :template => 'api/docs/template'
  end

  def search
    @page_title = I18n.t(:eol_api_search)
    render :template => 'api/docs/template'
  end

  def data_objects
    @page_title = I18n.t(:eol_api_data_objects)
    render :template => 'api/docs/template'
  end

  def pages
    @page_title = I18n.t(:eol_api_pages)
    render :template => 'api/docs/template'
  end

  def hierarchy_entries
    @page_title = I18n.t(:eol_api_hierarchy_entries)
    render :template => 'api/docs/template'
  end

  def provider_hierarchies
    @page_title = I18n.t(:eol_api_provider_hierarchies)
    render :template => 'api/docs/template'
  end

  def hierarchies
    @page_title = I18n.t(:eol_api_hierarchies)
    render :template => 'api/docs/template'
  end

  def search_by_provider
    @page_title = I18n.t(:eol_api_search_by_provider)
    render :template => 'api/docs/template'
  end

  def collections
    @page_title = I18n.t(:eol_api_collections)
    render :template => 'api/docs/template'
  end

private

  def set_method_name
    @api_method = params[:action]
  end

  def set_navigation_menu
    api_overview = ContentPage.find_by_page_name('api_overview', :include => :translations)
    unless api_overview.blank?
      translation = api_overview.translations.select{|t| t.language_id == current_language.id}.compact
      translation ||= api_overview.translations.select{|t| t.language_id == Language.english.id}.compact
      @navigation_menu =  translation.first.left_content rescue nil
      @navigation_menu.gsub!(/<li>(<a href=\"\/api\/docs\/#{params[:action]}\">)/, "<li class='active'>\\1")
    end
  end

  def create_documentation_hash
    # Standard structure of a documentation hash
    # { :method => {
    #     :sample_urls => [ ],
    #     :version => ,
    #     :description => ,
    #     :parameters => [
    #       { :name => ,
    #         :class => ,
    #         :required => ,
    #         :values => ,
    #         :default => ,
    #         :notes => ,
    #         :test_value => } ] }

    @documentation_hash = Rails.cache.fetch("api/docs/documentation/#{current_language.iso_code}", :expires_in => 1.day) do
      docs_hash = {}
      docs_hash[:ping] = ping_documentation
      docs_hash[:pages] = pages_documentation
      docs_hash[:search] = search_documentation
      docs_hash[:collections] = collections_documentation
      docs_hash[:data_objects] = data_objects_documentation
      docs_hash[:hierarchy_entries] = hierarchy_entries_documentation
      docs_hash[:hierarchies] = hierarchies_documentation
      docs_hash[:provider_hierarchies] = provider_hierarchies_documentation
      docs_hash[:search_by_provider] = search_by_provider_documentation
      docs_hash
    end
    @documentation = @documentation_hash[@api_method.to_sym]
  end

  def ping_documentation
    { :description => I18n.t(:ping_method_description) }
  end

  def search_documentation
    {
      :version => '1.0',
      :description =>
        I18n.t('the_xml_search_response_implements',
          :link => view_context.link_to('http://www.opensearch.org/Specifications/OpenSearch/1.1', 'http://www.opensearch.org/Specifications/OpenSearch/1.1')) +
        '</p><p>' + I18n.t('given_the_vast_number'),
      :parameters => [
        { :name => 'q',
          :class => 'Identifier',
          :required => true,
          :test_value => 'Ursus' },
        { :name => 'page',
          :class => Integer,
          :default => 1 },
        { :name => 'exact',
          :class => 'Boolean',
          :notes => I18n.t('limits_the_number_of_returned_image_objects') } ]
    }
  end

  def pages_documentation
    # European Honey Bee (Apis mellifera)
    test_taxon_concept = TaxonConcept.find(1045608) || TaxonConcept.last
    {
      :version => '1.0',
      :description => I18n.t(:page_method_description) + '</p><p>' +
        I18n.t('the_darwin_core_taxon_elements') +
        I18n.t('for_example_for_the_taxon_element_for_a_node',
          :link => view_context.link_to('hierarchy_entries', :action => 'hierarchy_entries')) +
        I18n.t('there_is_no_singular_eol',
          :link => view_context.link_to('hierarchy_entries', :action => 'hierarchy_entries')) + '</p><p>' +
        I18n.t('if_the_details_parameter_is_not_set',
          :linka => view_context.link_to(I18n.t('dublin_core'), 'http://dublincore.org/documents/dcmi-type-vocabulary/'),
          :linkb=> view_context.link_to(I18n.t('species_profile_model'), 'http://rs.tdwg.org/ontology/voc/SPMInfoItems')),
      :parameters => [
        { :name => 'id',
          :class => 'Identifier',
          :required => true,
          :test_value => test_taxon_concept.id },
        { :name => 'images',
          :class => Integer,
          :values => '0-75',
          :default => 1,
          :test_value => 2,
          :notes => I18n.t('limits_the_number_of_returned_image_objects') },
        { :name => 'videos',
          :class => Integer,
          :values => '0-75',
          :default => 1,
          :test_value => 0,
          :notes => I18n.t('limits_the_number_of_returned_video_objects') },
        { :name => 'sounds',
          :class => Integer,
          :values => '0-75',
          :default => 0,
          :notes => I18n.t('limits_the_number_of_returned_sound_objects') },
        { :name => 'maps',
          :class => Integer,
          :values => '0-75',
          :default => 0,
          :notes => I18n.t('limits_the_number_of_returned_map_objects') },
        { :name => 'text',
          :class => Integer,
          :values => '0-75',
          :default => 1,
          :test_value => 2,
          :notes => I18n.t('limits_the_number_of_returned_text_objects') },
        { :name => 'iucn',
          :class => 'Boolean',
          :notes => I18n.t('limits_the_number_of_returned_iucn_objects') },
        { :name => 'subjects',
          :class => String,
          :values => I18n.t('see_notes'),
          :default => 'overview',
          :notes => I18n.t('a_pipe_delimited_list_of_spm_info_item_subject_names') },
        { :name => 'licenses',
          :class => String,
          :values => 'cc-by, cc-by-nc, cc-by-sa, cc-by-nc-sa, pd ['+ I18n.t('public_domain') +'], na ['+ I18n.t('not_applicable') +'], all',
          :default => 'all',
          :notes => I18n.t('a_pipe_delimited_list_of_licenses', :creative_commons_link =>
            view_context.link_to(I18n.t('creative_commons'), 'http://creativecommons.org/licenses/', :rel => :nofollow)) },
        { :name => 'details',
          :class => 'Boolean',
          :test_value => 1,
          :notes => I18n.t('include_all_metadata') },
        { :name => 'common_names',
          :class => 'Boolean',
          :test_value => 1,
          :notes => I18n.t('return_common_names_for_the_page_taxon') },
        { :name => 'vetted',
          :class => Integer,
          :values => I18n.t("0_1_or_2"),
          :default => 0,
          :notes => I18n.t('return_content_by_vettedness') } ]
    }
  end

  def collections_documentation
    # Flickr partner collection
    test_collection = Collection.where(:name => 'EOL Group on Flickr').first || Collection.last
    {
      :version => '1.0',
      :description => I18n.t(:api_docs_collections_description),
      :parameters => [
        { :name => 'id',
          :class => 'Identifier',
          :required => true,
          :test_value => test_collection.id },
        { :name => 'page',
          :class => Integer,
          :default => 1 },
        { :name => 'per_page',
          :class => Integer,
          :default => 50 },
        { :name => 'filter',
          :class => String,
          :values => 'articles, collections, communities, images, sounds, taxa, users, video' },
        { :name => 'sort_by',
          :class => String,
          :values => SortStyle.all.map{ |ss| ss.name.downcase.gsub(' ', '_') rescue nil }.compact.join(', '),
          :default => SortStyle.newest.name.downcase.gsub(' ', '_') },
        { :name => 'sort_field',
          :class => String,
          :notes => I18n.t('collection_api_sort_field_notes') } ]
    }
  end

  def data_objects_documentation
    # picture of a honey bee http://eol.org/data_objects/21929584
    test_data_object = DataObject.latest_published_version_of_guid('d72801627bf4adf1a38d9c5f10cc767f') || DataObject.last
    {
      :version => '1.0',
      :description => I18n.t('data_object_api_description') + '</p><p>' + I18n.t('image_objects_will_contain_two_mediaurl_elements'),
      :parameters => [
        { :name => 'id',
          :class => 'Identifier',
          :required => true,
          :test_value => test_data_object.id } ]
    }
  end

  def hierarchy_entries_documentation
    # Bluefish (Pomatomus saltator)
    test_taxon_concept = TaxonConcept.find(205264) || TaxonConcept.last
    {
      :version => '1.0',
      :description => I18n.t('hierarchies_entries_description') + '</p><p>' + I18n.t('the_json_response_for_this_method'),
      :parameters => [
        { :name => 'id',
          :class => 'Identifier',
          :required => true,
          :test_value => test_taxon_concept.entry.id },
        { :name => 'common_names',
          :class => 'Boolean',
          :default => 1,
          :notes => I18n.t('return_all_common_names_for_this_taxon') },
        { :name => 'synonyms',
          :class => 'Boolean',
          :default => 1,
          :notes => I18n.t('return_all_synonyms_for_this_taxon') } ]
    }
  end

  def hierarchies_documentation
    {
      :version => '1.0',
      :description => I18n.t('hierarchies_description'),
      :parameters => [
        { :name => 'id',
          :class => 'Identifier',
          :required => true,
          :test_value => Hierarchy.default.id } ]
    }
  end

  def provider_hierarchies_documentation
    { :description => I18n.t(:provider_hierarchies_method_description) }
  end

  def search_by_provider_documentation
    url = url_for(:controller => '/api', :action => 'search_by_provider', :version => '1.0', :id => '180542', :hierarchy_id => Hierarchy.itis.id, :only_path => false)
    {
      :version => '1.0',
      :description => I18n.t("this_method_takes_an_integer_or_string",
        :link_provider => view_context.link_to("provider_hierarchies", :action => "provider_hierarchies"),
        :link_url => view_context.link_to(url, url),
        :itis_id => Hierarchy.itis.id),
      :parameters => [
        { :name => 'id',
          :class => 'Identifier',
          :required => true,
          :test_value => 180542 },
        { :name => 'hierarchy_id',
          :class => 'Identifier',
          :required => true,
          :test_value => Hierarchy.itis.id,
          :notes => I18n.t("the_id_of_provider_hierarchy_you_are_searching", :link => view_context.link_to('provider_hierarchies', :controller => 'api/docs', :action => 'provider_hierarchies')) }
      ]
    }
  end
end
