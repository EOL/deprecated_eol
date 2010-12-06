class ApiController < ApplicationController
  
  include ApiHelper
  
  before_filter :check_version, :handle_key
  layout 'main' , :only => [:index, :ping, :search, :pages, :data_objects, :hierarchy_entries, :provider_hierarchies, :search_by_provider]
  
  def pages
    taxon_concept_id = params[:id] || 0
    params[:format] ||= 'xml'
    params[:images] ||= 1
    params[:videos] ||= 1
    params[:text] ||= 1
    params[:vetted] ||= 0
    params[:version] ||= "0.1"
    params[:common_names] ||= false
    params[:common_names] = false if params[:common_names] == '0'
    params[:images] = 75 if params[:images].to_i > 75
    params[:videos] = 75 if params[:videos].to_i > 75
    params[:text] = 75 if params[:text].to_i > 75
    params[:details] = 1 if params[:format] == 'html'
    
    begin
      taxon_concept = TaxonConcept.find(taxon_concept_id)
      raise if taxon_concept.nil? || !taxon_concept.published?
    rescue
      render(:partial => 'error.xml.builder', :locals => {:error => "Unknown identifier #{taxon_concept_id}"})
      return
    end
    
    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.env["REQUEST_URI"], :method => 'pages', :version => params[:version], :format => params[:format], :request_id => taxon_concept_id, :key => @key, :user_id => @user_id)
    
    details_hash = taxon_concept.details_hash(:return_images_limit => params[:images].to_i, :return_videos_limit => params[:videos].to_i, :subjects => params[:subjects], :licenses => params[:licenses], :return_text_limit => params[:text].to_i, :details => params[:details], :vetted => params[:vetted], :common_names => params[:common_names])
    
    if params[:format] == 'html'
      render(:partial => 'pages', :layout=>false, :locals => {:details_hash => details_hash, :data_object_details => true } )
    elsif params[:version] == "1.0"
      respond_to do |format|
        format.xml { render(:partial => 'pages_1_0.xml.builder', :layout=>false, :locals => {:details_hash => details_hash, :data_object_details => params[:details] } ) }
        format.json {
          @return_hash = pages_json(details_hash, params[:details]!=nil)
          render :json => @return_hash, :callback => params[:callback] 
        }
      end
      
    else
      respond_to do |format|
        format.xml { render(:partial => 'pages', :layout=>false, :locals => {:details_hash => details_hash, :data_object_details => params[:details] } ) }
        format.json {
          @return_hash = pages_json(details_hash, params[:details]!=nil)
          render :json => @return_hash, :callback => params[:callback] 
        }
      end
    end
  end
  
  def data_objects
    data_object_guid = params[:id] || 0
    params[:format] ||= 'xml'
    params[:common_names] ||= false
    
    details_hash = DataObject.details_for_object(data_object_guid, :include_taxon => true, :common_names => params[:common_names])
    
    if details_hash.blank?
      render(:partial => 'error.xml.builder', :locals => {:error => "Unknown identifier #{data_object_guid}"})
      return
    end
    
    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.env["REQUEST_URI"], :method => 'data_objects', :version => params[:version], :format => params[:format], :request_id => data_object_guid, :key => @key, :user_id => @user_id)
    
    if params[:format] == 'html'
      render(:partial => 'pages', :layout => false, :locals => { :details_hash => details_hash, :data_object_details => true } )
    else
      respond_to do |format|
        format.xml { render(:partial => 'pages', :layout => false, :locals => { :details_hash => details_hash, :data_object_details => true } ) }
        format.json {
          @return_hash = pages_json(details_hash)
          render :json => @return_hash, :callback => params[:callback] 
        }
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
    
    @results = TaxonConcept.search_with_pagination(@search_term, :page => @page, :per_page => @per_page, :type => :all, :lookup_trees => false, :exact => params[:exact])
    @last_page = (@results.total_entries/@per_page.to_f).ceil
    
    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.env["REQUEST_URI"], :method => 'search', :version => params[:version], :format => params[:format], :request_id => @search_term, :key => @key, :user_id => @user_id)
    
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
    params[:common_names] ||= true
    params[:common_names] = false if params[:common_names] == '0'
    params[:synonyms] ||= true
    params[:synonyms] = false if params[:synonyms] == '0'
    
    begin
      @hierarchy_entry = HierarchyEntry.find(id)
      @ancestors = @hierarchy_entry.ancestor_details
      @common_names = params[:common_names] ? @hierarchy_entry.common_name_details : []
      @synonyms = params[:synonyms] ? @hierarchy_entry.synonym_details : []
      @children = @hierarchy_entry.children_details
      raise if @hierarchy_entry.nil? || !@hierarchy_entry.published?
    rescue
      render(:partial => 'error.xml.builder', :locals => {:error => "Unknown identifier #{id}"})
      return
    end
    
    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.env["REQUEST_URI"], :method => 'hierarchy_entries', :version => params[:version], :format => format, :request_id => id, :key => @key, :user_id => @user_id)
    
    if params[:format] == 'tcs'
      render :action =>'hierarchy_entries.xml.builder', :layout => false
    else
      respond_to do |format|
        format.xml { render :action =>'hierarchy_entries_dwc.xml.builder', :layout => false }
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
      render(:partial => 'error.xml.builder', :locals => {:error => "Unknown identifier #{id}"})
      return
    end
    
    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.env["REQUEST_URI"], :method => 'synonyms', :version => params[:version], :format => params[:format], :request_id => id, :key => @key, :user_id => @user_id)
    
    respond_to do |format|
       format.xml { render :layout => false }
    end
  end
  
  def hierarchies
    id = params[:id] || 0
    params[:format] ||= 'xml'
    
    begin
      @hierarchy = Hierarchy.find(id)
      @hierarchy_roots = @hierarchy.kingdom_details
      raise if @hierarchy.nil? || !@hierarchy.browsable?
    rescue
      render(:partial => 'error.xml.builder', :locals => {:error => "Unknown hierarchy #{id}"})
      return
    end
    
    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.env["REQUEST_URI"], :method => 'hierarchies', :version => params[:version], :format => params[:format], :request_id => id, :key => @key, :user_id => @user_id)
    
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
    
    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.env["REQUEST_URI"], :method => 'provider_hierarchies', :version => params[:version], :format => params[:format], :key => @key, :user_id => @user_id)
    
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
      render(:partial => 'error.xml.builder', :locals => {:error => "You must provide both the hierarchy id and the identifier"})
      return
    end
    @results = HierarchyEntry.find_all_by_hierarchy_id_and_identifier(params[:hierarchy_id], params[:id], :conditions => "published = 1 and visibility_id = #{Visibility.visible.id}")
    
    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.env["REQUEST_URI"], :method => 'search_by_provider', :version => params[:version], :format => params[:format], :request_id => params[:id], :key => @key, :user_id => @user_id)
    
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
    
    ApiLog.create(:request_ip => request.remote_ip, :request_uri => request.env["REQUEST_URI"], :method => 'ping', :version => params[:version], :format => params[:format], :key => @key, :user_id => @user_id)
    
    respond_to do |format|
      format.xml { render :layout => false }
      format.json { render :json => { 'response' => { 'message' => 'Success' } } , :callback => params[:callback] }
    end
  end
  
  def check_version
    return if params[:controller] == 'api/docs'
    if ['ping','pages','data_objects','hierarchy_entries','search','synonyms','provider_hierarchies','search_by_provider'].include? action_name
      unless ['0.4','1.0'].include? params[:version]
        render(:partial => 'error.xml.builder', :locals => {:error => "Unknown version #{params[:version]}"})
        return
      end
    end
  end

  private

  def handle_key
    @key = params[:key]
    user = @key ? User.find_by_api_key(@key) : nil
    @user_id = user.is_a?(User) ? user.id : nil
  end

end
