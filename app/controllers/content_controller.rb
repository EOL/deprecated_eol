class ContentController < ApplicationController

  layout 'v2/basic'
  include ActionView::Helpers::SanitizeHelper

  caches_page :tc_api

  prepend_before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN
  before_filter :set_session_hierarchy_variable, :only => [:index, :explore_taxa, :replace_single_explore_taxa]
  before_filter :redirect_if_curator , :only => [:page]

  def index
    @home_page = true
    current_user.log_activity(:viewed_home_page)
    begin
      @explore_taxa = $CACHE.fetch('homepage/random_images', :expires_in => 30.minutes) do
        RandomHierarchyImage.random_set(60)
      end
    rescue TypeError => e
      # TODO - FIXME  ... This appears to have to do with $CACHE.fetch (obviously)... not sure why, though.
      @explore_taxa = RandomHierarchyImage.random_set(60)
    end
    @explore_taxa.shuffle!
  end

  # just shows the top set of species --- can be included on other websites
  def species_bar
     @explore_taxa  = RandomHierarchyImage.random_set(6, nil, {:language => current_user.language, :size => :medium})
     @new_window = true
     render(:partial => 'explore_taxa')
  end

  def news
    id = params[:id]
    @term_search_string = params[:term_search_string] || ''
    search_string_parameter = '%' + @term_search_string + '%'
    if id.blank?
      @page_title = I18n.t(:whats_new)
      @news_items = NewsItem.paginate(:conditions => ['active = 1 and body like ?', search_string_parameter],
                                      :order => 'display_date desc',
                                      :page => params[:page])
      current_user.log_activity(:viewed_news_index)
    else
      @news_item = NewsItem.find(id)
      @page_title = @news_item.title # TODO: What happens if @news_item or title is nil
      current_user.log_activity(:viewed_news_item_id, :value => @news_item.id)
    end
    respond_to do |format|
       format.html
       format.rss { render :layout => false }
    end
  end

  def translate
    @page_title = I18n.t("automated_translation_of_eol")
    if params[:return_to].blank?
      @translate_url = root_url
    else
      if params[:return_to][0..3] != 'http'
        @translate_url = "http://#{request.host}#{params[:return_to]}"
      else
        @translate_url = params[:return_to]
      end
    end
  end

  def mediarss
    taxon_concept_id = params[:id] || 0
    taxon_concept = TaxonConcept.find(taxon_concept_id) rescue nil
    @items = []

    if !taxon_concept.nil?
      @title = "for "+ taxon_concept.quick_scientific_name(:normal)

      do_ids = TopConceptImage.find(:all,
        :select => 'data_object_id',
        :conditions => "taxon_concept_id = #{taxon_concept.id} AND view_order<400").collect{|tci| tci.data_object_id}

      data_objects = DataObject.find_all_by_id(do_ids,
        :select => {
          :data_objects => [ :guid, :object_cache_url ],
          :names => :string },
        :include => { :taxon_concepts => [ {:preferred_names => :name}, {:preferred_common_names => :name} ]})

      data_objects.each do |data_object|
        taxon_concept = data_object.taxon_concepts[0]
        title = taxon_concept.preferred_names[0].name.string
        unless taxon_concept.preferred_common_names.blank?
          title += ": #{taxon_concept.preferred_common_names[0].name.string}"
        end
        @items << {
          :title => title,
          :link => data_object_url(data_object.id),
          :permalink => data_object_url(data_object.id),
          :guid => data_object.guid,
          :thumbnail => DataObject.image_cache_path(data_object.object_cache_url, :medium),
          :image => DataObject.image_cache_path(data_object.object_cache_url, :orig),
        }
      end
      @items
    end

    respond_to do |format|
      format.rss { render :layout => false }
    end

  end

  # ------ /API -------

  def exemplars
    respond_to do |format|
      format.html do
        @page_title = I18n.t(:exemplar_pages)
        unless read_fragment(:controller => 'content', :part => 'exemplars')
          @exemplars = TaxonConcept.exemplars # This is stored by memcached, so should go quite fast.
        end
        current_user.log_activity(:viewed_exemplars)
      end
      format.xml do
        xml = $CACHE.fetch('examplars/xml') do
          TaxonConcept.exemplars.to_xml(:root => 'taxon-pages') # I don't know why the :root in TC doesn't work
        end
        render :xml => xml
      end
    end
  end

  #AJAX call to show more explore taxa on the home page
  def explore_taxa
    @explore_taxa = RandomHierarchyImage.random_set(6, @session_hierarchy,
                                                    {:language => current_user.language, :size => :medium})
    render :layout => false, :partial => 'explore_taxa'
  end

  #AJAX call to replace a single explore taxa for the home page
  def replace_single_explore_taxa

    params[:current_taxa] ||= ''
    params[:taxa_number] ||= '1'

    current_taxa = params[:current_taxa].split(',')
    explore_taxa = RandomHierarchyImage.random(@session_hierarchy, {:language => current_user.language, :size => :medium})

    # Ensure that we don't end up with duplicates, but not in development/test mode, where it makes things go a
    # bit haywire since there are very few random taxa created by scenarios.
    num_tries = 0
    while(num_tries < 30 and
          $PRODUCTION_MODE and
          !explore_taxa.blank? and
          current_taxa.include?(explore_taxa['taxon_concept_id'].to_s))
      explore_taxa = RandomHierarchyImage.random(@session_hierarchy, {:language => current_user.language, :size => :medium})
      num_tries += 1
    end

    taxa_number = params[:taxa_number]

    unless explore_taxa.nil? or taxa_number.nil? or taxa_number.empty?
      render :update do |page|
        name_div_contents = (random_image_linked_name(explore_taxa)).gsub(/'/, '&apos;')
        page << "$('#top_name_#{taxa_number}').html('#{name_div_contents}');"

        # we're now replacing the entire img tag which should prevent images from getting
        # stretched out in Safari and possibly other browsers
        image_div_contents = random_image_thumb_partial(explore_taxa, 'top_image_tag_'+taxa_number).gsub(/'/, '&apos;')
        page << "$('#top_image_tag_#{taxa_number}').parents('td').html('#{image_div_contents}');"
      end
    else
      render :nothing => true
    end

  end

  def contact_us

    @page_title = I18n.t(:contact_us_title)
    @subjects = ContactSubject.find(:all, :conditions => 'active = 1', :order => 'translated_contact_subjects.title')

    @contact = Contact.new(params[:contact])
    store_location(params[:return_to]) if !params[:return_to].nil? && request.get? # store the page we came from so we can return there if it's passed in the URL

    if request.post? == false
      return_to = params[:return_to] || ''
      # grab default subject to select in list if it's passed in the querystring
      @contact.contact_subject = ContactSubject.find_by_title(params[:default_subject]) if params[:default_subject].nil? == false
      @contact.name = params[:default_name] if params[:default_name].nil? == false
      @contact.email = params[:default_email] if params[:default_email].nil? == false
      return
    end

    @contact.ip_address = request.remote_ip
    @contact.user_id = current_user.id
    @contact.referred_page = return_to_url

    if verify_recaptcha && @contact.save
      Notifier.deliver_contact_us_auto_response(@contact)
      flash[:notice] =  I18n.t(:thanks_for_feedback)
      current_user.log_activity(:sent_contact_us_id, :value => @contact.id)
      redirect_back_or_default
    else
      @verification_did_not_match =  I18n.t(:verification_phrase_did_not_match)  if verify_recaptcha == false
    end

  end

  def media_contact
    @page_title = I18n.t(:media_contact)
    @contact = Contact.new(params[:contact])
    @contact.contact_subject = ContactSubject.find($MEDIA_INQUIRY_CONTACT_SUBJECT_ID)

    if request.post? == false
      store_location
      return
    end

    @contact.ip_address = request.remote_ip
    @contact.user_id = current_user.id
    @contact.referred_page = return_to_url

    if verify_recaptcha && @contact.save
      Notifier.deliver_media_contact_auto_response(@contact)
      flash[:notice] =  I18n.t(:your_message_was_sent)
      current_user.log_activity(:sent_media_contact_us_id, :value => @contact.id)
      redirect_back_or_default
    else
      @verification_did_not_match =  I18n.t(:verification_phrase_did_not_match)  if verify_recaptcha == false
    end

  end

  # the template for a static page with content from the database
  def page
    # get the id parameter, which can be either a page ID # or a page name
    @page_id = params[:id]
    raise "static page without id" if @page_id.blank?

    unless read_fragment(:controller => 'content', :part => @page_id + "_" + current_user.language_abbr)
      if @page_id.is_int?
        @content = ContentPage.find_by_id(@page_id)
      else # assume it's a page name
        page_name = @page_id.gsub(' ', '_').gsub('_', ' ')
        @content = ContentPage.find_by_page_name(page_name)
      end

      if @content.nil?
        raise "static page content #{@page_id} for #{current_user.language_abbr} not found"
      else
        @navigation_tree_breadcrumbs = ContentPage.get_navigation_tree_with_links(@content.id)
        current_language = Language.from_iso(current_user.language_abbr)
        @translated_content = TranslatedContentPage.find_by_content_page_id_and_language_id(@content.id, current_language.id)
        if @translated_content.nil?
          @page_title = I18n.t("cms_missing_content_title")
          @translated_pages = TranslatedContentPage.find_all_by_content_page_id(@content.id)
        else
          @page_title = @translated_content.title
        end

      end



      # if this static page is simply a redirect, then go there
      current_user.log_activity(:viewed_content_page_id, :value => @page_id)
    end
  end

  # convenience method to reference the uploaded content from the CMS (usually a PDF file or an image used in the static pages)
  def file

    content_upload_id = params[:id]

    raise "content upload without id" if content_upload_id.blank?

    # if the id is not numeric, assume it's a link name
    if content_upload_id.to_i == 0
      content_upload = ContentUpload.find_by_link_name(content_upload_id)
    else # assume the id passed is numeric and find it by ID
      content_upload = ContentUpload.find_by_id(content_upload_id)
    end

    raise "content upload not found" if content_upload.blank?

    # send them to the file on the content server
    redirect_to(content_upload.content_server_url)

  end

  # convenience method to reference the uploaded content from the CMS (usually a PDF file or an image used in the static pages)
  def files
    redirect_to(ContentServer.uploaded_content_url(params[:id], '.' + params[:ext].to_s))#params[:id].to_s.gsub(".")[1]))
  end

  # error page
  def error
    @page_title = I18n.t(:error_page_header)
  end

  # get the list of content partners
  def partners
    @page_title = I18n.t(:content_partners)
    # FIXME: missing association :content_partner below
    # content partners will have a username
    @partners = Agent.paginate(:conditions => 'username!="" AND content_partners.show_on_partner_page = 1', :order => 'agents.full_name asc', :include => :content_partner, :page => params[:page] || 1)

  end

  def donate
    @page_title = I18n.t(:donate)
    if request.post?
      current_user.log_activity(:made_donation)
    else
      current_user.log_activity(:viewed_donation)
    end

    return if request.post? == false

    donation = params[:donation]

    @other_amount = donation[:amount].gsub(",", "").to_f
    @preset_amount = donation[:preset_amount]

    if @preset_amount.nil?
      flash.now[:error] =  I18n.t(:donation_error_no_amount)
      return
    end

    if (@preset_amount == "other" && @other_amount == 0)
      flash.now[:error] =  I18n.t(:donation_error_only_numbers)
      return
    end

    @donation_amount = @preset_amount.to_f > 0 ? @preset_amount.to_f : @other_amount

    @page_title = I18n.t(:donation_confirmation) if @donation_amount > 0
    parameters = 'function=InsertSignature3&version=2&amount=' + @donation_amount.to_s + '&type=sale&currency=usd'
    @form_elements = EOLWebService.call(:parameters => parameters)

  end

  # conveninece page to expire everything immediately (call with http://www.eol.org/clear_caches)
  def clear_caches
    if allowed_request
      if clear_all_caches
        render :text => "All caches expired.", :layout => false
      else
        render :text => 'Clearing all caches not supported for this cache store.', :layout => false
      end
    else
      redirect_to root_url
    end
  end

  # conveninece page to expire all caches (except species pages) immediately (call with http://www.eol.org/expire_all)
  def expire_all
    if allowed_request
      expire_non_species_caches
      render :text => "Non-species page caches expired.", :layout => false
    else
      redirect_to root_url
    end
  end

  # conveninece page to expire a single CMS page immediately (call with http://www.eol.org/expire/PAGE_NAME)
  def expire_single
    if allowed_request
      expire_cache(params[:id])
      render :text => "Non-species page '#{params[:id]}' cache expired.", :layout => false
    else
      redirect_to root_url
    end
  end

  # show the user some taxon stats
  def stats
    @page_title = I18n.t("statistics")
    redirect_to root_url unless current_user.is_admin?  # don't release this yet...it's not ready for public consumption
    @stats = PageStatsTaxon.latest
  end

  # link to uservoice
  def feedback
    # FIXME: account/uservoice_login doesn't seem to exist ?
    if logged_in?
      redirect_to :controller => 'account', :action => 'uservoice_login'
    else
      redirect_to $USERVOICE_URL
    end
  end

  # TODO - is this even *used*?  I can't find it anywhere and it doesn't seem to work as expected when you call it's url.
  def expire_taxon
    if allowed_request && !params[:id].nil?
      begin
        expire_taxa([params[:id]])
        render :text => "Taxon ID #{params[:id]} and its ancestors expired.", :layout => false
      rescue => e
        render :text => "Could not expire Taxon Concept: #{e.message}", :layout => false
      end
    else
      redirect_to root_url
    end
  end

  # convenience page to expire a specific list of species page based on a comma delimited list of taxa IDs passed in as a
  # post or get with parameter taxa_ids (call with http://www.eol.org/expire_taxa)
  def expire_multiple
    taxa_ids = params[:taxa_ids]
    if allowed_request && !params[:taxa_ids].nil?
      expire_taxa(taxa_ids.split(','))
      render :text => "Taxa IDs #{taxa_ids} and their ancestors expired.", :layout => false
    else
      redirect_to root_url
    end
  end

  def wikipedia
    @revision_url = params[:revision_url]
    current_user.log_activity(:left_for_wikipedia_url, :value => @revision_url)
    @error = false
    if current_user.curator_approved
      if matches = @revision_url.match(/^http:\/\/en\.wikipedia\.org\/w\/index\.php\?title=(.*?)&oldid=([0-9]{9})$/i)
        flash[:notice] = I18n.t(:wikipedia_article_will_be_harvested_tonight, :article => matches[1], :rev => matches[2])
        WikipediaQueue.create(:revision_id => matches[2], :user_id => current_user.id)
        redirect_to :action => 'page', :id => 'curator_central'
      else
        flash[:notice] = I18n.t(:wikipedia_revisions_must_match_pattern_error)
        @revision_url = nil
        redirect_to :action => 'page', :id => 'curator_central'
      end
    end
  end

  def glossary
    @page_title = I18n.t("eol_glossary")
  end

end
