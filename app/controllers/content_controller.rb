class ContentController < ApplicationController

  layout 'main'

  before_filter :check_for_survey if $SHOW_SURVEYS
  prepend_before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN

  def index

    @home_page=true

    unless @cached_fragment = read_fragment(:controller=>'content',:part=>'home_' + current_user.language_abbr)
      @content=ContentPage.get_by_page_name_and_language_abbr('Home',current_user.language_abbr)
      raise "static page content not found" if @content.nil?
      @explore_taxa  = RandomTaxon.random_set(6)
      @featured_taxa = TaxonConcept.exemplars
      # get top news items less then a predetermined number of weeks old
      @news_items = NewsItem.find_all_by_active(true,:limit=>$NEWS_ITEMS_HOMEPAGE_MAX_DISPLAY,:order=>'display_date desc',:conditions=>'display_date >= "' + $NEWS_ITEMS_TIMEOUT_HOMEPAGE_WEEKS.weeks.ago.to_s(:db) + '"')
    end
      
  end
  
  # just shows the top set of species --- can be included on other websites
  def species_bar
     @explore_taxa  = RandomTaxon.random_set(6)
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
      @translate_url=home_page_url
    else
      @translate_url="http://#{request.host}#{params[:return_to]}"
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

    @explore_taxa=RandomTaxon.random_set(6)

    render :layout=>false,:partial => 'explore_taxa'
    
  end
  
  #AJAX call to replace a single explore taxa for the home page
  def replace_single_explore_taxa
 
     params[:current_taxa] ||= ''
     params[:taxa_number] ||= '1'
     
     current_taxa = params[:current_taxa].split(',')
     explore_taxa       = RandomTaxon.random
     # Ensure that we don't end up with duplicates, but not in development/test mode, where it makes things go a bit haywire since there are only 7 random taxa in the fixtures
  
     while ENV["RAILS_ENV"].downcase == 'production' && current_taxa.include?(explore_taxa.taxon_concept_id.to_s)
       explore_taxa = RandomTaxon.random
     end
  
     taxa_number        = params[:taxa_number]
     
     unless explore_taxa.nil? or taxa_number.nil? or taxa_number.empty?
       render :update do |page|
          page['top_image_tag_'+taxa_number].alt          = remove_html(explore_taxa.taxon_concept.name(:expert))
          page['top_image_tag_'+taxa_number].title        = remove_html(explore_taxa.taxon_concept.name(:expert))
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

    raise "static page without id" if @page_id.nil? || @page_id==''
    
    unless read_fragment(:controller=>'content',:part=>@page_id + "_" + current_user.language_abbr)
        # if the id is not numeric, assume it's a page name
        if @page_id.to_i == 0 
          page_name=@page_id.gsub(' ','_').gsub('_',' ')
          @content=ContentPage.get_by_page_name_and_language_abbr(page_name,current_user.language_abbr)
        else # assume the id passed is numeric and find it by ID
          @content=ContentPage.get_by_id_and_language_abbr(@page_id,current_user.language_abbr)
        end
        
        raise "static page content not found" if @content.nil?
        
        # if this static page is simply a redirect, then go there
        if !@content.url.blank?
          headers["Status"] = "301 Moved Permanently"
          redirect_to(@content.url)
        end
        
    end
  
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
      redirect_to home_page_url
    end
    
  end
     
  # conveninece page to expire all caches (except species pages) immediately (call with http://www.eol.org/expire_all)
  def expire_all
    
    if allowed_request
      expire_caches  
      render :text=>"Non-species page caches expired.",:layout=>false
    else
      redirect_to home_page_url
    end
    
  end

  # conveninece page to expire a single CMS page immediately (call with http://www.eol.org/expire/PAGE_NAME)
  def expire_single
    
    if allowed_request
      expire_cache(params[:id])
      render :text=>"Non-species page '" + params[:id] + "' cache expired.",:layout=>false
    else
      redirect_to home_page_url
    end
    
  end
  
  # convenience page to expire a specific species page based on a taxon ID (call with http://www.eol.org/expire/TAXON_ID)
  def expire
    
    if allowed_request && !params[:id].nil?
      if expire_taxon(params[:id])
         render :text=>'Taxon ID ' + params[:id] + ' and its ancestors expired.',:layout=>false
      else
         render :text=>'Invalid taxon ID supplied',:layout=>false
      end
    else
      redirect_to home_page_url
    end

  end

  # convenience page to expire a specific list of species page based on a comma delimited list of taxa IDs passed in as a post or get with parameter taxa_ids (call with http://www.eol.org/expire_taxa)
  def expire_multiple
    
    taxa_ids=params[:taxa_ids]

    if allowed_request && !params[:taxa_ids].nil?
      expire_taxa(taxa_ids.split(','))
      render :text=>'Taxa IDs ' + taxa_ids + ' and their ancestors expired.',:layout=>false
     else
       redirect_to home_page_url
     end
     
  end  
    
end
