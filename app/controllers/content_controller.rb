class ContentController < ApplicationController

  include ActionView::Helpers::SanitizeHelper
    
  caches_page :tc_api

  layout 'main'

  before_filter :check_for_survey if $SHOW_SURVEYS
  prepend_before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN
  before_filter :set_session_hierarchy_variable, :only => [:index, :explore_taxa, :replace_single_explore_taxa]

  def index

    @home_page=true

    unless @cached_fragment = read_fragment(:controller=>'content',:part=>'home_' + current_user.language_abbr)
      @content=ContentPage.get_by_page_name_and_language_abbr('Home',current_user.language_abbr)
      raise "static page content not found" if @content.nil?
      @explore_taxa  = RandomHierarchyImage.random_set(6, @session_hierarchy)
      @featured_taxa = TaxonConcept.exemplars
      # get top news items less then a predetermined number of weeks old
      @news_items = NewsItem.find_all_by_active(true,:limit=>$NEWS_ITEMS_HOMEPAGE_MAX_DISPLAY,:order=>'display_date desc',:conditions=>'display_date >= "' + $NEWS_ITEMS_TIMEOUT_HOMEPAGE_WEEKS.weeks.ago.to_s(:db) + '"')
    end
      
  end
  
  # just shows the top set of species --- can be included on other websites
  def species_bar
     @explore_taxa  = RandomHierarchyImage.random_set(6)
     @new_window = true
     render(:partial=>'explore_taxa')
  end
  
  def news
    id=params[:id]
    @term_search_string=params[:term_search_string] || ''
    search_string_parameter='%' + @term_search_string + '%' 
    if id.blank?
      @news_items=NewsItem.paginate(:conditions=>['active=1 and body like ?',search_string_parameter],:order=>'display_date desc',:page => params[:page])
    else
      @news_item=NewsItem.find(id)
    end
    respond_to do |format|
       format.html
       format.rss { render :layout=>false }
     end    
  end
  
  def translate
    if params[:return_to].blank?
      @translate_url=root_url
    else
      if params[:return_to][0..3]!='http'
        @translate_url="http://#{request.host}#{params[:return_to]}"       
      else
        @translate_url=params[:return_to]
      end
    end
  end
  
  def mediarss
    taxon_concept_id = params[:id] || 0
    taxon_concept = TaxonConcept.find(taxon_concept_id) rescue nil
    @items = []
    
    if !taxon_concept.nil?
      @title = "for "+ taxon_concept.quick_scientific_name(:normal)
    
      rows = SpeciesSchemaModel.connection.execute("SELECT tcn.taxon_concept_id, do.object_cache_url, do.object_title, do.guid FROM hierarchy_entries he JOIN top_images ti ON (he.id=ti.hierarchy_entry_id) JOIN data_objects do ON (ti.data_object_id=do.id) JOIN data_objects_taxa dot ON (do.id=dot.data_object_id) JOIN taxa t ON (dot.taxon_id=t.id) JOIN taxon_concept_names tcn ON (t.name_id=tcn.name_id) WHERE he.taxon_concept_id=#{taxon_concept.id} GROUP BY do.id ORDER BY ti.view_order").all_hashes
      
      rows.each do |row|
        @items << {
          :title => row['object_title'],
          :link => taxon_url(:id=>row['taxon_concept_id']),
          :guid => row['guid'],
          :thumbnail => DataObject.image_cache_path(row['object_cache_url'], :medium),
          :image => DataObject.image_cache_path(row['object_cache_url'], :orig)
        }
      end
    end
    
    respond_to do |format|
      format.rss { render :layout=>false }
    end
    
  end
  
  # ------ API -------

  #http://localhost:3000/content/tc_api/ shows all taxon concepts and http://localhost:3000/content/tc_api/page/2 shows second page of list. Also in public/content/ tc_api.gz appears
  def tc_api
    all_taxon_concepts = TaxonConcept.find(:all, :conditions => ["published = 1 AND  (supercedure_id = ? OR supercedure_id = ?)", 0, NIL])

    @all_taxon_concepts = all_taxon_concepts.paginate(:page => params[:page], :per_page => 25)
    
    text_tc   = all_taxon_concepts.map {|t| tc_api_tab(t) + "\n"}
    file_path = "#{RAILS_ROOT}/public/content/tc_api.gz"
    
    write_gz_api(text_tc, file_path)
    
    api_render(@all_taxon_concepts)
  end

  # put here an amount of random 5-star images we are needed
  def best_images
    taxon_concept_id = params[:id] || 0
    limit = params[:limit].to_i || 1
    limit = 1 if !limit.is_a? Integer
    limit = 1 if limit < 1
    limit = 100 if limit > 100
    taxon_concept = TaxonConcept.find(taxon_concept_id) rescue nil
    unless taxon_concept.nil?
      five_star_images = DataObject.for_taxon(taxon_concept, :image).map{|d| d.data_rating == 5.0 ? d : nil}.compact            
      if five_star_images.empty?
        text_to_write = ""
      elsif five_star_images.size < limit
        text_to_write = five_star_images
      else
        begin rand_best_images = Array.new(limit){ five_star_images[ rand( five_star_images.size ) ] } 
        end until rand_best_images.uniq.size == limit 
        text_to_write = rand_best_images
      end
      # uncomment if we need write .gz file on a disk
      # file_path = "#{RAILS_ROOT}/public/content/best_images.gz"
      # write_gz_api(text_to_write, file_path)
            
      @taxon_to_xml = taxon_to_xml(taxon_concept)
      @array_to_render = []
      for dato in text_to_write
         @array_to_render.push(dato_to_xml(dato))           
      end   
      text_to_write.blank? ? api_render(@taxon_to_xml) : api_render(@array_to_render)
    else
      render_404
    end
  end

  def api_render(array_to_render)
    unless array_to_render.blank?
      respond_to do |format|
         format.html
         format.xml { render :layout=>false }
      end
    else
     render_404
    end
  end
  
  def tc_api_tab(taxon_concept)
        taxon_concept.id.to_s + "\t" + 
        taxon_concept.scientific_name.gsub(/\t/, ' ') + "\t" + 
        taxon_concept.common_name.gsub(/\t/, ' ')
  end
  helper_method(:tc_api_tab)
    
  def write_gz_api(text_to_write, file_path)
    date_generated = "Generated on #{Time.now.strftime("%A, %B %d, %Y - %I:%M %p %Z")}"
    Zlib::GzipWriter.open(file_path) do |gzip|
  	  gzip << date_generated.to_s + "\n" + text_to_write.to_s
  	  gzip.close
  	end
  end  

  #TODO: add all tags from EOL Schema to use for all future APIs (e.g. see best_images.xml.builder)
  # http://services.eol.org/schema/documentation_0_2.pdf
  def taxon_to_xml(taxon_concept)
    schema_ranks = ['kingdom', 'phylum', 'class', 'order', 'family', 'genus']
    taxon_params = Hash[];
    taxon_params["identifier"] = taxon_concept.id
    taxon_concept.entry.ancestors.each do |ancestor|
      if ancestor.rank && schema_ranks.include?(ancestor.rank.label)
        taxon_params[ancestor.rank.label] = ancestor.name
      end
    end
    taxon_params["ScientificName"] = taxon_concept.scientific_name
    return taxon_params                                                               
  end

  #TODO: add all tags from EOL Schema to use for all future APIs (e.g. see best_images.xml.builder)
  # http://services.eol.org/schema/documentation_0_2.pdf
  def dato_to_xml(dato)
    
    dato_params = Hash[]
    
    dato_params["identifier"]    = dato.id
    dato_params["dataType"]      = dato.data_type.schema_value
    dato_params["mimeType"]      = dato.mime_type.label
    dato_params["agents"] = []
    dato.agents_data_objects.each do |ado|
      agent = Hash[]
      agent["homepage"] = ado.agent.homepage
      if ado.agent.logo_url
        agent["logoURL"] = "http://www.eol.org" + ado.agent.logo_url 
      end
      agent["role"]        = ado.agent_role.label.downcase
      agent["fullName"] = ado.agent.full_name
      dato_params["agents"] << agent
    end
		dato_params["created"]		    = dato.object_created_at
		dato_params["modified"]	    = dato.object_modified_at
		dato_params["language"]	    = dato.language.iso_639_1
		dato_params["license"]		    = dato.license.source_url
		dato_params["rights"]		    = dato.rights_statement
		dato_params["rightsHolder"]  = dato.rights_holder
		dato_params["bibliographicCitation"] = dato.bibliographic_citation
		dato_params["source"]	      = dato.source_url
		dato_params["description"]		= dato.description
		dato_params["mediaURL"]		  = dato.thumb_or_object
		dato_params["thumbnailURL"]	= dato.thumb_or_object(:small)
    dato_params["location"]      = dato.location
    
    return dato_params                                                              
  end

  # ------ /API -------
  
  def exemplars
    respond_to do |format|
      format.html do
        unless read_fragment(:controller=>'content',:part=>'exemplars')
          @exemplars = TaxonConcept.exemplars # This is stored by memcached, so should go quite fast.
        end
      end
      format.xml do
        xml = Rails.cache.fetch('examplars/xml') do
          TaxonConcept.exemplars.to_xml(:root => 'taxon-pages') # I don't know why the :root in TC doesn't work
        end
        render :xml => xml
      end
    end
  end
  
  #AJAX call to show more explore taxa on the home page
  def explore_taxa
    @explore_taxa=RandomHierarchyImage.random_set(6, @session_hierarchy)

    render :layout=>false,:partial => 'explore_taxa'
    
  end
  
  #AJAX call to replace a single explore taxa for the home page
  def replace_single_explore_taxa
 
    params[:current_taxa] ||= ''
    params[:taxa_number] ||= '1'
     
    current_taxa = params[:current_taxa].split(',')
    explore_taxa       = RandomHierarchyImage.random(@session_hierarchy)

    # Ensure that we don't end up with duplicates, but not in development/test mode, where it makes things go a
    # bit haywire since there are very few random taxa created by scenarios.
    num_tries = 0
    while(num_tries < 30 and
          $PRODUCTION_MODE and
          !explore_taxa.blank? and
          current_taxa.include?(explore_taxa.taxon_concept_id.to_s))
      explore_taxa = RandomHierarchyImage.random(@session_hierarchy)
      num_tries += 1
    end

    taxa_number = params[:taxa_number]
    
    unless explore_taxa.nil? or taxa_number.nil? or taxa_number.empty?
      render :update do |page|
        page['top_image_tag_'+taxa_number].alt          = sanitize(explore_taxa.taxon_concept.name(:expert))
        page['top_image_tag_'+taxa_number].title        = sanitize(explore_taxa.taxon_concept.name(:expert))
        page['top_image_tag_'+taxa_number].src          = explore_taxa.data_object.smart_medium_thumb
        page['top_image_tag_'+taxa_number+'_href'].href = "/pages/" + explore_taxa.taxon_concept_id.to_s
        page.replace_html 'top_name_'+taxa_number, linked_name(explore_taxa.taxon_concept)
      end
    else
      render :nothing=>true
    end
    
  end
  
  def contact_us
 
    @subjects = ContactSubject.find(:all, :conditions=>'active=1',:order => 'title')

    @contact = Contact.new(params[:contact])
    store_location(params[:return_to]) if !params[:return_to].nil? && request.get? # store the page we came from so we can return there if it's passed in the URL
    
    if request.post? == false
      return_to=params[:return_to] || ''
      # grab default subject to select in list if it's passed in the querystring
      @contact.contact_subject=ContactSubject.find_by_title(params[:default_subject]) if params[:default_subject].nil? == false   
      @contact.name=params[:default_name] if params[:default_name].nil? == false
      @contact.email=params[:default_email] if params[:default_email].nil? == false
      return
    end 
    
    @contact.ip_address=request.remote_ip
    @contact.user_id=current_user.id
    @contact.referred_page=return_to_url
    
    if verify_recaptcha && @contact.save  
      Notifier.deliver_contact_us_auto_response(@contact)
      flash[:notice]="Thank you for your feedback."[:thanks_for_feedback]
      redirect_back_or_default
    else
      @verification_did_not_match="The verification phrase you entered did not match."[:verification_phrase_did_not_match] if verify_recaptcha == false
    end
    
  end
  
  def media_contact
    
    @contact = Contact.new(params[:contact])
    @contact.contact_subject=ContactSubject.find($MEDIA_INQUIRY_CONTACT_SUBJECT_ID)
    
    if request.post? == false
      store_location
      return
    end

    @contact.ip_address=request.remote_ip
    @contact.user_id=current_user.id
    @contact.referred_page=return_to_url
    
    if verify_recaptcha && @contact.save
      Notifier.deliver_media_contact_auto_response(@contact)
      flash[:notice]="Your message was sent."[:your_message_was_sent]
      redirect_back_or_default 
    else
      @verification_did_not_match="The verification phrase you entered did not match."[:verification_phrase_did_not_match] if verify_recaptcha == false
    end
    
  end
  
  # the template for a static page with content from the database
  def page
    # get the id parameter, which can be either a page ID # or a page name
    @page_id=params[:id]

    raise "static page without id" if @page_id.blank?
    
    unless read_fragment(:controller=>'content',:part=>@page_id + "_" + current_user.language_abbr)
        # if the id is not numeric, assume it's a page name
        if @page_id.to_i == 0 
          page_name=@page_id.gsub(' ','_').gsub('_',' ')
          @content=ContentPage.get_by_page_name_and_language_abbr(page_name,current_user.language_abbr)
        else # assume the id passed is numeric and find it by ID
          @content=ContentPage.get_by_id_and_language_abbr(@page_id,current_user.language_abbr)
        end
        
        raise "static page content #{@page_id} for #{current_user.language_abbr} not found" if @content.nil?
        
        # if this static page is simply a redirect, then go there
        if !@content.url.blank?
          headers["Status"] = "301 Moved Permanently"
          redirect_to(@content.url)
        end
        
    end
  
  end
  
  # convenience method to reference the uploaded content from the CMS (usually a PDF file or an image used in the static pages)
  def file
    
    content_upload_id=params[:id]

    raise "content upload without id" if content_upload_id.blank?
    
    # if the id is not numeric, assume it's a link name
    if content_upload_id.to_i == 0 
      content_upload=ContentUpload.find_by_link_name(content_upload_id)
    else # assume the id passed is numeric and find it by ID
      content_upload=ContentUpload.find_by_id(content_upload_id)
    end
        
    raise "content upload not found" if content_upload.blank?
    
    # send them to the file on the content server
    redirect_to(content_upload.content_server_url)
    
  end
  
  # error page
  def error
  end
  
  # get the list of content partners
  def partners
  
    # content partners will have a username
    @partners=Agent.paginate(:conditions=>'username<>"" AND content_partners.show_on_partner_page = 1',:order=>'agents.full_name asc',:include=>:content_partner,:page => params[:page] || 1)
    
  end
  
  def donate
    
    return if request.post? == false
    
    donation=params[:donation]

    @other_amount=donation[:amount].gsub(",","").to_f 
    @preset_amount=donation[:preset_amount]
   
    if @preset_amount.nil?
      flash.now[:error]="Please select a donation amount."[:donation_error]
      return
    end
    
    if (@preset_amount == "other" && @other_amount == 0)
      flash.now[:error]="Please enter an amount using only numbers."[:donation_error2]
      return
    end
  
    @donation_amount = @preset_amount.to_f > 0 ? @preset_amount.to_f : @other_amount
    @transaction_type = "sale"
    @currency = "usd"
    
    parameters='function=InsertSignature3&version=2&amount=' + @donation_amount.to_s + '&type=' + @transaction_type + '&currency=' + @currency
    @form_elements=EOLWebService.call(:parameters=>parameters)
 
  end

  # conveninece page to expire everything immediately (call with http://www.eol.org/clear_caches)
  def clear_caches
    
    if allowed_request
      if clear_all_caches
        render :text=>"All caches expired.",:layout=>false
      else
        render :text=>'Clearing all caches not supported for this cache store.', :layout=>false
      end  
    else
      redirect_to root_url
    end
    
  end
     
  # conveninece page to expire all caches (except species pages) immediately (call with http://www.eol.org/expire_all)
  def expire_all
    
    if allowed_request
      expire_caches  
      render :text=>"Non-species page caches expired.",:layout=>false
    else
      redirect_to root_url
    end
    
  end

  # conveninece page to expire a single CMS page immediately (call with http://www.eol.org/expire/PAGE_NAME)
  def expire_single
    
    if allowed_request
      expire_cache(params[:id])
      render :text=>"Non-species page '" + params[:id] + "' cache expired.",:layout=>false
    else
      redirect_to root_url
    end
    
  end
  
  # show the user some taxon stats
  def stats
    redirect_to root_url unless current_user.is_admin?  # don't release this yet...it's not ready for public consumption
    @stats=PageStatsTaxon.latest
  end
  
  # link to uservoice
  def feedback
    
    if logged_in?
      redirect_to :controller=>'account',:action=>'uservoice_login'
    else
      redirect_to $USERVOICE_URL
    end
      
  end
  
  # convenience page to expire a specific species page based on a taxon ID (call with http://www.eol.org/expire/TAXON_ID)
  def expire
    
    if allowed_request && !params[:id].nil?
      if expire_taxon_concept(params[:id])
         render :text=>'Taxon ID ' + params[:id] + ' and its ancestors expired.',:layout=>false
      else
         render :text=>'Invalid taxon ID supplied',:layout=>false
      end
    else
      redirect_to root_url
    end

  end

  # convenience page to expire a specific list of species page based on a comma delimited list of taxa IDs passed in as a post or get with parameter taxa_ids (call with http://www.eol.org/expire_taxa)
  def expire_multiple
    
    taxa_ids=params[:taxa_ids]

    if allowed_request && !params[:taxa_ids].nil?
      expire_taxa(taxa_ids.split(','))
      render :text=>'Taxa IDs ' + taxa_ids + ' and their ancestors expired.',:layout=>false
     else
       redirect_to root_url
     end
     
  end  
    
end
