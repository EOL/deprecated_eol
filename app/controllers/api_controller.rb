class ApiController < ApplicationController

  include ApiHelper

  before_filter :check_version, :handle_key
  layout 'main' , :only => [ :index, :ping, :search, :pages, :data_objects, :hierarchy_entries, :hierarchies,
    :provider_hierarchies, :search_by_provider, :collections ]

  def pages
    taxon_concept_id = params[:id] || 0
    params[:format] ||= 'xml'
    params[:images] ||= 1
    params[:videos] ||= 1
    params[:text] ||= 1
    params[:vetted] ||= nil
    params[:common_names] ||= false
    params[:common_names] = false if params[:common_names] == '0'
    params[:synonyms] ||= false
    params[:synonyms] = false if params[:synonyms] == '0'
    params[:images] = 75 if params[:images].to_i > 75
    params[:videos] = 75 if params[:videos].to_i > 75
    params[:text] = 75 if params[:text].to_i > 75
    params[:sounds] = 75 if params[:sounds].to_i > 75
    params[:maps] = 75 if params[:maps].to_i > 75
    params[:details] = 1 if params[:format] == 'html'

    begin
      taxon_concept = TaxonConcept.find(taxon_concept_id, :include => { :published_hierarchy_entries => [ :hierarchy, :name ] })
      raise if taxon_concept.blank? || !taxon_concept.published?
    rescue
      render_error("Unknown identifier #{taxon_concept_id}")
      return
    end
    ApiLog.create(:request_ip => request.remote_ip,
                  :request_uri => request.fullpath,
                  :method => 'pages',
                  :version => params[:version],
                  :format => params[:format],
                  :request_id => taxon_concept_id,
                  :key => @key,
                  :user_id => @user_id)

    data_objects = taxon_concept.data_objects_for_api(params)
    if params[:version] == "1.0"
      respond_to do |format|
        format.xml do
          render(:partial => 'pages_1_0',
                 :layout => false,
                 :locals => { :taxon_concept => taxon_concept, :data_objects => data_objects, :params => params } )
        end
        format.json do
          @return_hash = pages_json(taxon_concept, data_objects, params[:details] != nil)
          render :json => @return_hash, :callback => params[:callback]
        end
      end
    else
      respond_to do |format|
        format.xml do
          render(:partial => 'pages',
                 :layout => false,
                 :locals => { :taxon_concept => taxon_concept, :data_objects => data_objects, :params => params } )
        end
        format.json do
          @return_hash = pages_json(taxon_concept, data_objects, params[:details] != nil)
          render :json => @return_hash, :callback => params[:callback]
        end
      end
    end
  end

  def data_objects
    data_object_guid = params[:id] || 0
    params[:format] ||= 'xml'
    params[:common_names] ||= false
    params[:details] = true

    begin
      d = DataObject.find_by_guid(data_object_guid)
      data_object = d.latest_version_in_same_language(:check_only_published => true)
      if data_object.blank?
        data_object = d.latest_version_in_same_language(:check_only_published => false)
      end
      raise if data_object.blank?
      data_object = DataObject.find_by_id(data_object.id)
      raise if data_object.blank?
      taxon_concept = data_object.all_associations.first.taxon_concept
    rescue
      render_error("Unknown identifier #{data_object_guid}")
      return
    end

    ApiLog.create(:request_ip => request.remote_ip,
                  :request_uri => request.fullpath,
                  :method => 'data_objects',
                  :version => params[:version],
                  :format => params[:format],
                  :request_id => data_object_guid,
                  :key => @key,
                  :user_id => @user_id)

    respond_to do |format|
      format.xml do
        render(:partial => 'pages',
               :layout => false,
               :locals => { :taxon_concept => taxon_concept, :data_objects => [data_object], :params => params } )
      end
      format.json do
        @return_hash = pages_json(taxon_concept, [data_object])
        render :json => @return_hash, :callback => params[:callback]
      end
    end
  end

  def search
    @search_term = params[:id]
    params[:format] ||= 'xml'
    params[:exact] = params[:exact] == "1" ? true : false
    @page = params[:page].to_i || 1
    @page = 1 if @page < 1
    @per_page = 30

    if(!params[:filter_by_taxon_concept_id] || params[:filter_by_taxon_concept_id]=='')
      params[:filter_by_taxon_concept_id]=false
    end
    if(!params[:filter_by_hierarchy_entry_id] || params[:filter_by_hierarchy_entry_id]=='')
      params[:filter_by_hierarchy_entry_id]=false
    end
    if(!params[:filter_by_string] || params[:filter_by_string]=='')
      params[:filter_by_string]=false
    end

    # we had a bunch of searches like "link:QLlHJCZzx" which were throwing errors
    if @search_term.blank? || @search_term.match(/^link:[a-z]+$/i)
      render_error("Invalid search term: #{@search_term}")
      return
    end

    search_response = EOL::Solr::SiteSearch.search_with_pagination(@search_term, :page => @page, :per_page => @per_page, :type => ['taxon_concept'], :exact => params[:exact],
      :filter_by_taxon_concept_id => params[:filter_by_taxon_concept_id],
      :filter_by_hierarchy_entry_id => params[:filter_by_hierarchy_entry_id],
      :filter_by_string => params[:filter_by_string])

    @results = search_response[:results]
    @last_page = (@results.total_entries/@per_page.to_f).ceil

    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.fullpath, :method => 'search', :version => params[:version], :format => params[:format], :request_id => @search_term, :key => @key, :user_id => @user_id)

    respond_to do |format|
      format.xml { render :layout => false }
      format.json {
          @return_hash = search_result_hash({:search_term => @search_term, :page => @page, :per_page => @per_page, :results => @results, :format => params[:format]})
          render :json => @return_hash, :callback => params[:callback]
        }
    end
  end

  def hierarchy_entries
    id = params[:id] || 0
    format = params[:format] || 'dwc'
    @include_common_names = params[:common_names] || true
    @include_common_names = false if params[:common_names] == '0'
    @include_synonyms = params[:synonyms] || true
    @include_synonyms = false if params[:synonyms] == '0'

    begin
      associations = [ { :name => :canonical_form }]
      selects = { :hierarchy_entries => '*', :canonical_forms => [ :id, :string ] }
      if @include_common_names
        associations << { :common_names => [:name, :language] }
        selects[:languages] = [ :id, :iso_639_1 ]
      end
      if @include_synonyms
        associations << { :scientific_synonyms => [:name, :synonym_relation] }
      end

      @hierarchy_entry = HierarchyEntry.find(id)
      @hierarchy_entry.preload_associations(associations, :select => selects)
      @ancestors = @hierarchy_entry.ancestors
      @ancestors.pop # remove the last element which is the node itself
      @children = @hierarchy_entry.children
      raise if @hierarchy_entry.nil? || !@hierarchy_entry.published?
    rescue
      render_error("Unknown identifier #{id}")
      return
    end

    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.fullpath, :method => 'hierarchy_entries', :version => params[:version], :format => format, :request_id => id, :key => @key, :user_id => @user_id)
    
    if params[:render] == 'tcs'
      render :action =>'hierarchy_entries', :layout => false
    else
      respond_to do |format|
        format.xml { render :action =>'hierarchy_entries_dwc', :layout => false }
        format.json {
          @return_hash = hierarchy_entries_json
          render :json => @return_hash, :callback => params[:callback]
        }
      end
    end
  end

  def synonyms
    id = params[:id] || 0
    params[:format] ||= 'xml'

    begin
      @synonym = Synonym.find(id)
    rescue
      render_error("Unknown identifier #{id}")
      return
    end

    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.fullpath, :method => 'synonyms', :version => params[:version], :format => params[:format], :request_id => id, :key => @key, :user_id => @user_id)

    respond_to do |format|
       format.xml { render :layout => false }
    end
  end

  def hierarchies
    id = params[:id] || 0
    params[:format] ||= 'xml'

    begin
      @hierarchy = Hierarchy.find(id)
      @hierarchy_roots = @hierarchy.kingdoms
      raise if @hierarchy.nil? || !@hierarchy.browsable?
    rescue
      render_error("Unknown hierarchy #{id}")
      return
    end

    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.fullpath, :method => 'hierarchies', :version => params[:version], :format => params[:format], :request_id => id, :key => @key, :user_id => @user_id)

    respond_to do |format|
      format.xml { render :layout => false }
      format.json {
        @return_hash = hierarchies_json
        render :json => @return_hash, :callback => params[:callback]
      }
    end
  end

  def provider_hierarchies
    params[:format] ||= 'xml'

    @hierarchies = Hierarchy.browsable

    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.fullpath, :method => 'provider_hierarchies', :version => params[:version], :format => params[:format], :key => @key, :user_id => @user_id)

    respond_to do |format|
      format.xml { render :layout => false }
      format.json {
        @return_hash = eol_providers_json
        render :json => @return_hash, :callback => params[:callback]
      }
    end
  end

  def search_by_provider
    params[:format] ||= 'xml'
    begin
      raise if params[:hierarchy_id].blank? || params[:id].blank?
    rescue
      render_error("You must provide both the hierarchy id and the identifier")
      return
    end
    @results = HierarchyEntry.find_all_by_hierarchy_id_and_identifier(params[:hierarchy_id], params[:id], :conditions => "published = 1 and visibility_id = #{Visibility.visible.id}")

    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.fullpath, :method => 'search_by_provider', :version => params[:version], :format => params[:format], :request_id => params[:id], :key => @key, :user_id => @user_id)

    respond_to do |format|
      format.xml { render :layout => false }
      format.json {
        @return_hash = search_by_providers_json
        render :json => @return_hash, :callback => params[:callback]
      }
    end
  end

  def ping
    params[:format] ||= 'xml'

    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.fullpath, :method => 'ping', :version => params[:version], :format => params[:format], :key => @key, :user_id => @user_id)

    respond_to do |format|
      format.xml { render :layout => false }
      format.json { render :json => { 'response' => { 'message' => 'Success' } } , :callback => params[:callback] }
    end
  end

  def ping_host
    respond_to do |format|
      format.json { render :json => { 'response' => { 'host' => request.host, 'port' => request.port } } }
    end
  end

  def collections
    id = params[:id] || 0
    params[:format] ||= 'xml'
    @page = params[:page].to_i || 1
    @page = 1 if @page < 1
    @per_page = params[:per_page].to_i || 50
    @filter = nil
    unless params[:filter].blank? || params[:filter].class != String
      @filter = params[:filter].singularize.split(' ').join('_').camelize
    end

    begin
      @collection = Collection.find_by_id(id, :include => [ :sort_style ])
      @sort_by = @collection.default_sort_style
      if !params[:sort_by].blank? && params[:sort_by].class == String && ss = SortStyle.find_by_translated(:name, params[:sort_by].titleize)
        @sort_by = ss
      end
      @facet_counts = EOL::Solr::CollectionItems.get_facet_counts(@collection.id)
      @collection_results = @collection.items_from_solr(:facet_type => @filter, :page => params[:page], :per_page => @per_page, :sort_by => @sort_by)
      @collection_items = @collection_results.map { |i| i['instance'] }
      CollectionItem.preload_associations(@collection_items, :refs)
      raise if @collection.blank?
    rescue
      render_error("Unknown identifier #{id}")
      return
    end

    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.fullpath,
                  :method => 'collections', :version => params[:version], :format => params[:format],
                  :request_id => id, :key => @key, :user_id => @user_id)

    respond_to do |format|
      format.xml { render :layout => false }
      format.json { render :json => collections_json, :callback => params[:callback] }
    end
  end

  # this method wil ensure the version provided is valid, and set the default version to the latest API version
  def check_version
    return if params[:controller] == 'api/docs'
    params[:version] ||= '1.0'
    if ['ping','pages','data_objects','hierarchy_entries','search','synonyms','provider_hierarchies','search_by_provider','collections'].include? action_name
      unless ['0.4','1.0'].include? params[:version]
        render_error("Unknown version #{params[:version]}")
        return
      end
    end
  end

  private
  
  def render_error(error_message)
    respond_to do |format|
      format.xml { render(:partial => 'error', :locals => { :error => error_message }) }
      format.json { render(:json => [ :error => error_message ], :callback => params[:callback] ) }
    end
  end

  def handle_key
    @key = params[:key]
    user = @key ? User.find_by_api_key(@key) : nil
    @user_id = user.is_a?(User) ? user.id : nil
  end

end
