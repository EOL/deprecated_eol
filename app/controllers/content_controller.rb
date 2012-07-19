class ContentController < ApplicationController

  include ActionView::Helpers::SanitizeHelper

  caches_page :tc_api

  layout 'v2/basic'

  prepend_before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN

  before_filter :login_with_open_authentication, :only => :index
  before_filter :check_user_agreed_with_terms, :except => [:show, :random_homepage_images]

  skip_before_filter :original_request_params, :only => :random_homepage_images
  skip_before_filter :global_warning, :only => :random_homepage_images
  skip_before_filter :redirect_to_http_if_https, :only => :random_homepage_images
  skip_before_filter :clear_any_logged_in_session, :only => :random_homepage_images
  skip_before_filter :check_user_agreed_with_terms, :only => :random_homepage_images
  skip_before_filter :set_locale, :only => :random_homepage_images

  def index
    @rel_canonical_href = root_url.sub!(/\/+$/,'')
    @home_page = true
    @explore_taxa = safely_shuffle(RandomHierarchyImage.random_set_cached)
    @rich_pages_path = language_dependent_collection_path
    if current_user.news_in_preferred_language
      @translated_news_items = TranslatedNewsItem.find(:all, :conditions=>['translated_news_items.language_id = ? and translated_news_items.active_translation=1 and news_items.active=1 and news_items.activated_on<=?', Language.from_iso(current_language.iso_639_1), DateTime.now.utc], :joins => "inner join news_items on news_items.id = translated_news_items.news_item_id", :order=>'news_items.display_date desc', :limit => $NEWS_ON_HOME_PAGE)
    else
      news_items = NewsItem.find(:all, :conditions=>['news_items.active=1 and news_items.activated_on<=?', DateTime.now.utc],
        :order=>'news_items.display_date desc', :include => :translations, :limit => $NEWS_ON_HOME_PAGE)
      @translated_news_items = []
      news_items.each do |news_item|
        translations = news_item.translations
        if translated_news_item = translations.detect{|tr| tr.language_id == current_language.id}
          @translated_news_items << translated_news_item
        else
          @translated_news_items << translations.sort_by{ |t| t.created_at || 0 }.first
        end
      end
    end
    current_user.log_activity(:viewed_home_page)
    periodically_recalculate_homepage_parts
  end

  def random_homepage_images
    begin
      number_of_images = (params[:count] && params[:count].is_numeric?) ? params[:count].to_i : 1
      number_of_images = 1 if number_of_images < 1 || number_of_images > 10
      random_images = RandomHierarchyImage.random_set(number_of_images).map do |random_image|
        { :image_url => random_image.taxon_concept.exemplar_or_best_image_from_solr.thumb_or_object('130_130'),
          :taxon_scientific_name => random_image.taxon_concept.title_canonical,
          :taxon_common_name => random_image.taxon_concept.preferred_common_name_in_language(current_language),
          :taxon_page_path => taxon_overview_path(random_image.taxon_concept_id) }
      end
      render :json => random_images, :callback => params[:callback]
    rescue
      render :json => { :error => "Error retrieving random images" }
    end
  end

  def replace_single_explore_taxa
    render :text => I18n.t(:please_refresh)
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
          :thumbnail => DataObject.image_cache_path(data_object.object_cache_url, '98_68'),
          :image => DataObject.image_cache_path(data_object.object_cache_url, :orig),
        }
      end
      @items
    end

    respond_to do |format|
      format.rss { render :layout => false }
    end

  end

  # GET /info/:id
  # GET /info/:crumbs where crumbs is an array of path segments
  def show
    # get the id parameter, which can be either a page ID # or a page name
    @page_id = params[:id] || params[:crumbs].last

    # temporarily forcing all new RSS requests to return HTML to address on of our most common bugs
    if @page_id == 'news' && params[:format] == 'rss'
      params[:format] = 'html'
    end

    if @page_id.is_int?
      @content = ContentPage.find(@page_id, :include => [:parent, :translations])
    else # assume it's a page name
      @content = ContentPage.find_by_page_name(@page_id, :include => [:parent, :translations])
      @content ||= ContentPage.find_by_page_name(@page_id.gsub('_', ' '), :include => [:parent, :translations]) # will become obsolete once validation on page_name is in place
      raise ActiveRecord::RecordNotFound, "Couldn't find ContentPage with page_name=#{@page_id}" if @content.nil?
    end

    if ! @content.nil? && ! current_user.can_read?(@content) && ! logged_in?
      raise EOL::Exceptions::MustBeLoggedIn, "Non-authenticated user does not have read access to ContentPage with ID=#{@content.id}"
    elsif ! current_user.can_read?(@content)
      raise EOL::Exceptions::SecurityViolation, "User with ID=#{current_user.id} does not have read access to ContentPage with ID=#{@content.id}"
    else # page exists so now we look for actual content i.e. a translated page
      if @content.translations.blank?
        raise ActiveRecord::RecordNotFound, "Couldn't find TranslatedContentPage with content_page_id=#{@content.id}"
      else
        translations_available_to_user = @content.translations.select{|t| current_user.can_read?(t)}.compact
        if translations_available_to_user.blank?
          if logged_in?
            raise EOL::Exceptions::SecurityViolation, "User with ID=#{current_user.id} does not have read access to any TranslatedContentPage with content_page_id=#{@content.id}"
          else
            raise EOL::Exceptions::MustBeLoggedIn, "Non-authenticated user does not have read access to any TranslatedContentPage with content_page_id=#{@content.id}"
          end
        else
          # try and render preferred language translation, otherwise links to other available translations will be shown
          @selected_language = params[:language] ? Language.from_iso(params[:language]) :
            Language.from_iso(current_language.iso_639_1)
          @translated_pages = translations_available_to_user
          @translated_content = translations_available_to_user.select{|t| t.language_id == @selected_language.id}.compact.first
          @page_title = @translated_content.nil? ? I18n.t(:cms_missing_content_title) : @translated_content.title
          @navigation_tree_breadcrumbs = ContentPage.get_navigation_tree_with_links(@content.id)
          current_user.log_activity(:viewed_content_page_id, :value => @page_id)
          @rel_canonical_href = cms_page_url(@content)
        end
      end
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
    redirect_to(content_upload.content_server_url, :status => :moved_permanently)

  end

  # convenience method to reference the uploaded content from the CMS (usually a PDF file or an image used in the static pages)
  def files
    redirect_to(ContentServer.uploaded_content_url(params[:id], '.' + params[:ext].to_s))#params[:id].to_s.gsub(".")[1]))
  end

  def loggertest
    time = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    logger.fatal "~~ FATAL #{time}"
    logger.error "** ERROR #{time}"
    logger.warn  "!! WARN #{time}"
    logger.info  "++ INFO #{time}"
    logger.debug ".. DEBUG #{time}"
    render :text => "Logs written at #{time}."
  end

  def boom
    raise "This is an exception." # I18n not req'd
  end

  def language
    @page_title = I18n.t(:site_language)
    if request.post? == false
      store_location(request.referer)
    else
      selected_language = params[:site_language][:language]
      redirect_to set_language_url(:language => selected_language)+"&return_to=#{session[:return_to]}"
    end
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
      redirect_to root_url, :status => :moved_permanently
    end
  end

  # conveninece page to expire all caches (except species pages) immediately (call with http://www.eol.org/expire_all)
  def expire_all
    if allowed_request
      expire_non_species_caches
      render :text => "Non-species page caches expired.", :layout => false
    else
      redirect_to root_url, :status => :moved_permanently
    end
  end

  # conveninece page to expire a single CMS page immediately (call with http://www.eol.org/expire/PAGE_NAME)
  def expire_single
    if allowed_request
      expire_cache(params[:id])
      render :text => "Non-species page '#{params[:id]}' cache expired.", :layout => false
    else
      redirect_to root_url, :status => :moved_permanently
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
      redirect_to root_url, :status => :moved_permanently
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
      redirect_to root_url, :status => :moved_permanently
    end
  end

  def glossary
    @page_title = I18n.t("eol_glossary")
  end

private

  def periodically_recalculate_homepage_parts
    $CACHE.fetch('homepage/activity_logs_expiration/' + current_language.iso_639_1, :expires_in => $HOMEPAGE_ACTIVITY_LOG_CACHE_TIME.minutes) do
      expire_fragment(:action => 'index', :action_suffix => "activity_#{current_language.iso_639_1}")
    end
    $CACHE.fetch('homepage/march_of_life_expiration/' + current_language.iso_639_1, :expires_in => 120.seconds) do
      expire_fragment(:action => 'index', :action_suffix => "march_of_life_#{current_language.iso_639_1}")
    end
  end

  def safely_shuffle(what)
    begin
      what.shuffle!
    rescue TypeError => e # it's a frozen array, it's been cached somewhere.
      what = (@explore_taxa.nil?) ? @explore_taxa : @explore_taxa.dup.shuffle!
    end
  end

  def language_dependent_collection_path
    if $RICH_LANG_PAGES_COLLECTION_IDS && $RICH_LANG_PAGES_COLLECTION_IDS.has_key?(I18n.locale)
      collection_path($RICH_LANG_PAGES_COLLECTION_IDS[I18n.locale])
    else
      collection_path($RICH_PAGES_COLLECTION_ID)
    end
  end
end
