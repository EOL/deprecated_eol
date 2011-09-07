class ContentController < ApplicationController

  include ActionView::Helpers::SanitizeHelper

  caches_page :tc_api

  layout :choose_layout

  prepend_before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN
  before_filter :check_user_agreed_with_terms, :except => [:show]

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

    # recalculate the activity logs on homepage every $HOMEPAGE_ACTIVITY_LOG_CACHE_TIME minutes
    $CACHE.fetch('homepage/activity_logs_expiration', :expires_in => $HOMEPAGE_ACTIVITY_LOG_CACHE_TIME.minutes) do
      expire_fragment(:action => 'index', :action_suffix => "activity_#{current_user.language_abbr}")
    end

    # recalculate the activity logs on homepage every $HOMEPAGE_ACTIVITY_LOG_CACHE_TIME minutes
    $CACHE.fetch('homepage/march_of_life_expiration', :expires_in => 60.seconds) do
      expire_fragment(:action => 'index', :action_suffix => 'march_of_life')
    end

    begin
      @explore_taxa.shuffle!
    rescue TypeError => e # it's a frozen array, it's been cached somwhere.
      @explore_taxa = @explore_taxa.dup
      @explore_taxa.shuffle!
    end
  end

  def replace_single_explore_taxa
    render :text => I18n.t(:please_refresh)
  end

  def preview
    @home_page = true
    return redirect_to root_path unless $PREVIEW_LOCKDOWN
    if request.post?
      if params[:preview] == $PREVIEW_LOCKDOWN
        session[:preview] = params[:preview]
        return redirect_to root_path
      else
        flash.now[:error] = "Incorrect password."
        return render :layout => false
      end
    end
    render :layout => false
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

  # GET /info/:id
  # GET /info/:crumbs where crumbs is an array of path segments
  def show
    # get the id parameter, which can be either a page ID # or a page name
    @page_id = params[:id] || params[:crumbs].last
    @selected_language = params[:language] ? Language.from_iso(params[:language]) : nil
    raise "static page without id" if @page_id.blank?

    # Temporarily having to deal with some legacy V1 URLs (see routes file - should not be needed after October 10 2011)
    # but we don't want the user to see or bookmark them so:
    redirect_to cms_page_path(@page_id) if current_url.match(/^\/content\/page\//)

    if @page_id.is_int?
      @content = ContentPage.find(@page_id, :include => :parent)
    else # assume it's a page name
      @content = ContentPage.find_by_page_name(@page_id)
      @content ||= ContentPage.find_by_page_name(@page_id.gsub('_', ' ')) # will become obsolete once validation on page_name is in place
    end

    return render_404 if @content.nil? || !current_user.can_read?(@content)

    @navigation_tree_breadcrumbs = ContentPage.get_navigation_tree_with_links(@content.id)
    current_language = @selected_language || Language.from_iso(current_user.language_abbr)
    @translated_content = TranslatedContentPage.find_by_content_page_id_and_language_id(@content.id, current_language.id)
    @translated_content = nil unless current_user.can_read?(@translated_content)
    if @translated_content.nil?
      @translated_pages = TranslatedContentPage.find_all_by_content_page_id(@content.id)
      @translated_pages.reject!{|tp| !current_user.can_read?(tp)}
      return render_404 if @translated_pages.blank?
      @page_title = I18n.t(:cms_missing_content_title)
    else
      @page_title = @translated_content.title
    end
    current_user.log_activity(:viewed_content_page_id, :value => @page_id)
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

  # error page
  def error
    @page_title = begin
                    I18n.t(:error_page_title)
                  rescue
                    'ERROR'
                  end
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

  def glossary
    @page_title = I18n.t("eol_glossary")
  end

private

  def choose_layout
    case action_name
    when 'error'
      'v2/errors'
    else
      'v2/basic'
    end
  end
end
