require 'uri'
ContentPage # TODO - figure out why this fails to autoload.  Look at http://kballcodes.com/2009/09/05/rails-memcached-a-better-solution-to-the-undefined-classmodule-problem/

class ApplicationController < ActionController::Base
  filter_parameter_logging :password
  include ContentPartnerAuthenticationModule # TODO -seriously?!?  You want all that cruft available to ALL controllers?!
  include ImageManipulation

  if $EXCEPTION_NOTIFY || $ERROR_LOGGING
    include ExceptionNotifiable
    # Uncomment this line if you want to test exception notification and db error logging even on localhost calls.
    # You'll probably also need to set config.action_controller.consider_all_requests_local = false in your
    # environment file:
    #local_addresses.clear
  end

  # If recaptcha is not enabled, then override the method to always return true
  unless $ENABLE_RECAPTCHA
    def verify_recaptcha
      true
    end
  end

  before_filter :preview_lockdown if $PREVIEW_LOCKDOWN
  before_filter :global_warning if $GLOBAL_WARNING
  before_filter :check_if_mobile if $ENABLE_MOBILE

  prepend_before_filter :redirect_to_http_if_https
  prepend_before_filter :set_session
  before_filter :clear_any_logged_in_session unless $ALLOW_USER_LOGINS
  before_filter :check_user_agreed_with_terms, :except => :error

  helper :all

  helper_method :logged_in?, :current_url, :current_user, :return_to_url, :current_agent, :agent_logged_in?,
    :allow_page_to_be_cached?, :link_to_item

  before_filter :set_locale

  # Continuously display a warning message.  This is used for things like "System Shutting down at 15 past" and the
  # like.  And, yes, if there's a "real" error, they won't see the message because flash[:error] will be
  # over-written.  But so it goes.  This is the final countdown.
  def global_warning
    flash[:error] ||= $GLOBAL_WARNING # Global warning is not a myth.
  end

  def preview_lockdown
    if $PREVIEW_LOCKDOWN == true || session[:preview] != $PREVIEW_LOCKDOWN
      return redirect_to preview_url unless params[:controller] == 'content' && params[:action] == 'preview'
    end
  end

  def set_locale
    begin
      I18n.locale = current_user.language_abbr
    rescue
      I18n.locale = 'en' # Yes, I am hard-coding that because I don't want an error from Language.  Ever.
    end
  end

  def rescue_action(e)
    case e
    when EOL::Exceptions::MustBeLoggedIn
      must_be_logged_in
    when EOL::Exceptions::SecurityViolation
      access_denied
    when EOL::Exceptions::Pending
      not_yet_implemented
    else
      # NOTE - Solr connection was failing often enough that I thought it warranted special handling.
      @@solr_error_re ||= /^Connection refused/  # Remember REs cause mem leaks if in-line
      if e.message =~ @@solr_error_re
        logger.error "****\n**** ERROR: Solr connection refused.\n****"
        @solr_connection_refused = true
      else
        resolve_common_session_errors
        log_error_cleanly(e)
      end
      @page_title = I18n.t(:error_page_title)
      respond_to do |format|
        format.html { render :layout => 'v2/errors', :template => "content/error" }
        format.js { @retry = false; render :layout => false, :template => "content/error" }
      end
      raise e # This lets New Relic handle the actual exception.  ...may cause some dupe logs in devel, though
    end
  end

  def allow_login_then_submit
    unless logged_in?
      # TODO: Can we delete the submitted data if the user doesn't login or signup?
      session[:submitted_data] = params
      # POST request should provide a submit_to URL so that we can redirect to the correct action with a GET.
      submit_to = params[:submit_to] || current_url
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:must_be_logged_in)
          redirect_to login_path(:return_to => submit_to)
        end
        format.js do
          render :partial => 'content/must_login', :layout => false, :locals => { :return_to => submit_to }
        end
      end
    end
  end

  def must_be_logged_in
    flash[:warning] =  I18n.t(:must_be_logged_in)
    session[:return_to] = request.url if params[:return_to].nil?
    redirect_to(login_path, :return_to => params[:return_to])
  end

  def view_helper_methods
    Helper.instance
  end

  class Helper
    include Singleton
    include TaxaHelper
    include ApplicationHelper
    include ActionView::Helpers::SanitizeHelper
  end

  # override exception notifiable default methods to redirect to our special error pages instead of the usual 404
  # and 500 and to do error logging
  def render_404
    @page_title = I18n.t(:error_404_page_title)
    respond_to do |type|
      type.html { render :layout => 'v2/errors', :template => "content/missing", :status => 404} # status may be redundant
      type.all  { render :nothing => true }
    end
  end

  def render_500(exception = nil)
    if $ERROR_LOGGING && !$IGNORED_EXCEPTIONS.include?(exception.to_s)
       ErrorLog.create(
         :url => request.url,
         :ip_address => request.remote_ip,
         :user_agent => request.user_agent,
         :user_id => current_user.id,
         :exception_name => exception.to_s,
         :backtrace => "Application Server: " + $IP_ADDRESS_OF_SERVER + "\r\n" + exception.backtrace.to_s
         )
    end
    @page_title = I18n.t(:error_500_page_title)
    respond_to do |type|
     type.html { render :layout => 'v2/errors', :template => "content/error"}
     type.all  { render :nothing => true }
    end
  end
  ## end override of exception notifiable default methods

  # this method determines if the main taxa page is allowed to be cached or not
  def allow_page_to_be_cached?
    return !(agent_logged_in? or current_user.is_admin?)
  end

  # store a given URL (defaults to current) in case we need to redirect back later
  def store_location(url = url_for(:controller => controller_name, :action => action_name))
    # It's possible to create a redirection attack with a redirect to data: protocol... and possibly others, so:
    # Whitelisting redirection to our own site and relative paths.
    url = nil unless url =~ /\A([%2F\/]|#{root_url})/
    session[:return_to] = url
  end

  # retrieve url stored in session by store_location()
  # use redirect_back_or_default to specify a default url, do not add default here
  def return_to_url
    session[:return_to]
  end

  def valid_return_to_url
    return_to_url != nil && return_to_url != login_url && return_to_url != new_user_url && return_to_url != logout_url && !url_for(:controller => 'content_partner', :action => 'login', :only_path => true).include?(return_to_url)
  end

  def current_url(remove_querystring = true)
    if remove_querystring
      current_url = URI.parse(request.url).path
    else
      request.url
    end
  end

  def referred_url
    request.referer
  end

  # Redirect to the URL stored by the most recent store_location call or to the passed default.
  def redirect_back_or_default(default = root_url(:protocol => "http"))
    # be sure we aren't returning the login, register or logout page
    if valid_return_to_url
      url = CGI.unescape(return_to_url)
      url = {:controller => url, :protocol => "http"} unless  url.match("://")
      redirect_to(url)
    else
      redirect_to(default)
    end
    store_location(nil)
    return false
  end

  # send user to the SSL version of the page (used in the account controller, can be used elsewhere)
  def redirect_to_ssl
    url_to_return = params[:return_to] ? CGI.unescape(params[:return_to]).strip : nil
    unless request.ssl? || local_request?
      if url_to_return && url_to_return[0...1] == '/'  #return to local url
        redirect_to :protocol => "https://", :return_to => url_to_return, :method => request.method
      else
        redirect_to :protocol => "https://", :method => request.method
      end
    end
  end

  def collected_errors(model_object)
    error_list = ''
    model_object.errors.each{|attr, msg| error_list += "#{attr} #{msg}," }
    return error_list.chomp(',')
  end

  # called to log and redirect a user to an external link
  def external_link

    url = params[:url]
    if url.nil?
      render :nothing => true
      return
    end

    ExternalLinkLog.log url, request, current_user

    redirect_to url

  end

  def redirect_to_http_if_https
    if request.ssl?
      redirect_to "http://" + request.host + request.request_uri
    end
  end

  # check to see if a session exists, and create if it not
  #  even non-logged in users get a session to store their expertise and language preferences
  def set_session
    unless logged_in?
      create_new_user
      clear_old_sessions if $USE_SQL_SESSION_MANAGEMENT
      # expire home page fragment caches after specified internal to keep it fresh
      if $CACHE_CLEARED_LAST.advance(:hours => $CACHE_CLEAR_IN_HOURS) < Time.now
        expire_cache('home')
        $CACHE_CLEARED_LAST = Time.now()
      end
    end
  end

  # expire a single non-species page fragment cache
  def expire_cache(page_name)
    expire_pages(ContentPage.find_all_by_page_name(page_name))
  end

  # just clear all fragment caches quickly
  def clear_all_caches
    $CACHE.clear
    remove_cached_feeds
    remove_cached_list_of_taxon_concepts
    if ActionController::Base.cache_store.class == ActiveSupport::Cache::MemCacheStore
      ActionController::Base.cache_store.clear
      return true
    else
      return false
    end
  end

  def expire_non_species_caches
    expire_menu_caches
    expire_pages(ContentPage.find_all_by_active(true))
    $CACHE_CLEARED_LAST = Time.now()
  end

  # expire a list of taxa_ids specifed as an array, usually including its ancestors (optionally not)
  # NOTE - this is VERY slow because each taxon is expired individually.  But this is a limitation of memcached.  Unless we
  # want to keep an index of all of the memcached keys related to a given taxon, which itself would be confusing, this is not
  # really possible.
  def expire_taxa(taxa_ids)
    return if taxa_ids.nil?
    raise "Must be called with an array" unless taxa_ids.class == Array
    taxa_ids_to_expire = find_ancestor_ids(taxa_ids)
    return if taxa_ids_to_expire.nil? # Yes, again.  Sorry.
    if taxa_ids_to_expire.length > $MAX_TAXA_TO_EXPIRE_BEFORE_EXPIRING_ALL
      Rails.cache.clear
    else
      expire_taxa_ids_with_error_handling(taxa_ids_to_expire)
    end
  end

  def expire_data_object(data_object_id)
    # TODO: re-implement caching and review caching practices
  end

  # NOTE: If you want to expire it's ancestors, too, use #expire_taxa.
  def expire_taxon_concept(taxon_concept_id, params = {})
    # TODO: re-implement caching and review caching practices
  end

  # check if the requesting IP address is allowed (used to resrict methods to specific IPs, such as MBL/EOL IPs)
  def allowed_request
    !((request.remote_ip =~ /127\.0\.0\.1/).nil? && (request.remote_ip =~ /128\.128\./).nil? && (request.remote_ip =~ /10\.19\./).nil?)
  end


  # send user back to the non-SSL version of the page
  def redirect_back_to_http
    redirect_to :protocol => "http://" if request.ssl?
  end

  # default new user when we don't have a logged in user
  def create_new_user
    session[:user_id] = nil
    user = User.create_new(:remote_ip => request.remote_ip)
    user.language_abbr= session[:language] if session[:language] # Recalls language from previous session.
    user
  end

  # return currently logged in user
  def current_user
    if logged_in?
      session[:user] = nil
      return temporary_logged_in_user ? temporary_logged_in_user :
                                        set_temporary_logged_in_user(cached_user)
    else
      session[:user] ||= create_new_user # if there wasn't one
      session[:user] = create_new_user unless session[:user].respond_to?(:stale?)
      session[:user] = create_new_user if session[:user].stale?
      return session[:user]
    end
  end

  # For the duration of the request, change some of the values on this User.
  #
  # NOTE: if you want to change a User's settings for more than one request, use alter_current_user
  # function.
  def set_current_user(user)
    if user.new_record?
      set_unlogged_in_user(user)
    else
      set_logged_in_user(user)
    end
  end

  # This is actually kind of tricky, since we need to actually save things if the user is logged in, but not if they
  # aren't.  It also involves cache-clearing and the like, so be careful about skipping the set_current_user method.
  def alter_current_user(&block)
    user = current_user
    user = User.find(user.id) if user.frozen? # Since we're modifying it, we can't use the one from memcached.
    yield(user)
    user.save if logged_in?
    $CACHE.delete("users/#{session[:user_id]}")
    set_current_user(user)
    user
  end

  # this method is used as a before_filter when user logins are disabled to ensure users who may have had a previous
  # session before we switched off user logins is booted out
  def clear_any_logged_in_session
    if logged_in?
      session[:user] = nil
      session[:user_id] = nil
      current_agent = nil
    end
  end


  ###########
  # AUTHENTICATION/AUTHORIZATION METHODS

  # check to see if we have a logged in user
  def logged_in?
    return(logged_in_from_session? || logged_in_from_cookie?)
  end

  def logged_in_from_session?
    begin
      if session[:user_id]
        if u = cached_user
          return true
        else
          # I had a problem when switching environments when my session use didn't exist, and this should help fix that
          session[:user_id] = nil
        end
      end
    rescue ActionController::SessionRestoreError => e
      reset_session
      logger.warn "!! Rescued a corrupt session."
    end
    return false
  end

  def logged_in_from_cookie?
    begin
      user = cookies[:user_auth_token] && !cookies[:user_auth_token].blank? && User.find_by_remember_token(cookies[:user_auth_token])
      if user
        if user.language && user.respond_to?(:stale?) && ! user.stale?
          cookies[:user_auth_token] = { :value => user.remember_token, :expires => user.remember_token_expires_at }
          set_logged_in_user(user)
          return true
        else
          cookies[:user_auth_token] = nil
          logger.info "++ Removed an invalid user_auth_token cookie."
        end
      end
    rescue ActionController::SessionRestoreError => e
      reset_session
      logger.warn "!! Rescued a corrupt cookie."
    end
    return false
  end

  def check_authentication
    must_log_in unless logged_in?
    return false
  end

  # used as a before_filter on methods that you don't want users to see if they are logged in
  # such as the sessions#new, users#new, users#forgot_password etc
  def redirect_if_already_logged_in
    if logged_in?
      flash[:notice] = I18n.t(:destination_inappropriate_for_logged_in_users)
      redirect_to(current_user)
    end
  end

  def must_log_in
    respond_to do |format|
      format.html { store_location; redirect_to login_url }
      format.js   { render :partial => 'content/must_login', :layout => false }
    end
    return false
  end

  # call this method if someone is not supposed to get a controller or action when user accounts are disabled
  def accounts_not_available
    flash[:warning] =  I18n.t(:user_system_down)
    redirect_to root_url
  end

  def restrict_to_admins
    raise EOL::Exceptions::SecurityViolation unless current_user.is_admin?
  end

  def restrict_to_curators
    raise EOL::Exceptions::SecurityViolation unless current_user.min_curator_level?(:full)
  end

  # A user is not authorized for the particular controller/action:
  def access_denied
    unless logged_in?
      return redirect_to root_url
    end
    store_location(request.referer) unless session[:return_to] || request.referer.blank?
    flash_and_redirect_back(I18n.t(:you_are_not_authorized_to_perform_this_action))
  end

  def not_yet_implemented
    flash[:warning] =  I18n.t(:not_yet_implemented_error)
    redirect_to request.referer ? :back : :default
  end

  def flash_and_redirect_back(msg)
    flash[:error] = msg
    respond_to do |format|
      format.html { redirect_back_or_default }
      format.js { render :text => warning }
    end
  end

  # Set the current language
  def set_language
    language = params[:language].to_s
    unless language.blank?
      session[:language] = nil # Don't want to "remember" this anymore, since they've manually changed it.
      alter_current_user do |user|
        I18n.locale = language
        user.language = Language.from_iso(language)
      end
    end
    return_to = (params[:return_to].blank? ? root_url : params[:return_to])
    redirect_to return_to
  end

  # pulled over from Rails core helper file so it can be used in controllers as well
  def escape_javascript(javascript)
     (javascript || '').gsub('\\', '\0\0').gsub('</', '<\/').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
  end

  # logged in users will be redirected to terms agreement if they have not yet accepted.
  def check_user_agreed_with_terms
    if logged_in? && ! current_user.agreed_with_terms
      store_location
      redirect_to terms_agreement_user_path(current_user)
    end
  end

  def redirect_to_missing_page_on_error(&block)
    begin
      yield
    rescue => e
      @page_title = I18n.t(:error_404_page_title)
      @message = e.message
      render(:layout => 'v2/errors', :template => "content/missing", :status => 404)
      return false
    end
  end

  # Ensure that the user has this in their watch_colleciton, so they will get replies in their newsfeed:
  def auto_collect(what, options = {})
    options[:annotation] ||= I18n.t(:user_left_comment_on_date, :username => current_user.full_name,
                                    :date => I18n.l(Date.today))
    watchlist = current_user.watch_collection
    collection_item = CollectionItem.find_by_collection_id_and_object_id_and_object_type(watchlist.id, what.id,
                                                                                         what.class.name)
    if collection_item.nil?
      collection_item = begin # No care if this fails.
        CollectionItem.create(:annotation => options[:annotation], :object => what, :collection_id => watchlist.id)
      rescue => e
        logger.error "** ERROR COLLECTING: #{e.message} FROM #{e.backtrace.first}"
        nil
      end
      if collection_item && collection_item.save
        return unless what.respond_to?(:summary_name) # Failsafe.  Most things should.
        flash[:notice] ||= ''
        flash[:notice] += ' '
        flash[:notice] += I18n.t(:item_added_to_watch_collection_notice,
                                 :collection_name => self.class.helpers.link_to(watchlist.name,
                                                                                collection_path(watchlist)),
                                 :item_name => what.summary_name)
        CollectionActivityLog.create(:collection => watchlist, :user => current_user,
                             :activity => Activity.collect, :collection_item => collection_item)
      end
    end
  end

  def convert_flash_messages_for_ajax
    [:notice, :error].each do |type|
      if flash[type]
        temp = flash[type]
        flash[type] = ''
        flash.now[type] = temp
      end
    end
  end

  def link_to_item(item)
    case item.class.name
    when 'Collection'
      collection_url(item)
    when 'Community'
      community_url(item)
    when 'DataObject'
      data_object_url(item)
    when 'User'
      user_url(item)
    when 'TaxonConcept'
      taxon_concept_url(item)
    else
      raise EOL::Exceptions::ObjectNotFound
    end
  end


private

  def find_ancestor_ids(taxa_ids)
    taxa_ids = taxa_ids.map do |taxon_concept_id|
      taxon_concept = TaxonConcept.find_by_id(taxon_concept_id)
      taxon_concept.nil? ? nil : taxon_concept.ancestry.collect {|an| an.taxon_concept_id}
    end
    taxa_ids.flatten.compact.uniq
  end

  def expire_taxa_ids_with_error_handling(taxa_ids_to_expire)
    messages = []
    taxa_ids_to_expire.each do |id|
      begin
        expire_taxon_concept(id)
      rescue => e
        messages << "Unable to expire TaxonConcept #{id}: #{e.message}"
      end
    end
    raise messages.join('; ') unless messages.empty?
  end

  def remove_cached_feeds
    FileUtils.rm_rf(Dir.glob("#{RAILS_ROOT}/public/feeds/*"))
  end

  def remove_cached_list_of_taxon_concepts
    FileUtils.rm_rf("#{RAILS_ROOT}/public/content/tc_api/page")
    expire_page( :controller => 'content', :action => 'tc_api' )
  end

  # Rails cache (memcached, probably) version of the user, by id:
  def cached_user
    User # KNOWN BUG (in Rails): if you end up with "undefined class/module" errors in a fetch() call, you must call
         # that class beforehand.
    $CACHE.fetch("users/#{session[:user_id]}") { User.find(session[:user_id]) rescue nil }
  end

  # Having a *temporary* logged in user, as opposed to reading the user from the cache, lets us change some values
  # (such as language or vetting) within the scope of a request *without* storing it the database.  So, for example,
  # when a URL includes "&vetted = true" (or some-such), we can serve that request with *temporary* user values that
  # don't change the user's DB values.
  def temporary_logged_in_user
    @logged_in_user
  end

  def set_temporary_logged_in_user(user)
    @logged_in_user = user
  end

  # There are several things we need to do when we change the (temporary) values on a logged-in user:
  def set_logged_in_user(user)
    set_temporary_logged_in_user(user)
    session[:user_id] = user.id
    set_unlogged_in_user(nil)
  end

  def unlogged_in_user
    session[:user]
  end

  def set_unlogged_in_user(user)
    session[:user] = user
  end

  def expire_pages(pages)
    if pages.length > 0
      Language.find_active.each do |language|
        pages.each do |page|
          if page.class == ContentPage
            expire_fragment(:controller => '/content', :part => "#{page.id.to_s }_#{language.iso_639_1}")
            expire_fragment(:controller => '/content',
                            :part => "#{page.page_url.underscore_non_word_chars.downcase}_#{language.iso_639_1}")
            page.clear_all_caches rescue nil # TODO - still having some problem with ContentPage, not sure why.
          else
            expire_fragment(:controller => '/content', :part => "#{page}_#{language.iso_639_1}")
          end
          if page.class == ContentPage && page.page_url == 'home'
            Hierarchy.all.each do |h|
              expire_fragment(:controller => '/content', :part => "home_#{language.iso_639_1}_#{h.id.to_s}") # this is because the home page fragment is dependent on the user's selected hierarchy entry ID, unlike the other content pages
            end
          end
        end
      end
    end
  end

  def clear_old_sessions
    CGI::Session::ActiveRecordStore::Session.destroy_all( ['updated_at <?', $SESSION_EXPIRY_IN_SECONDS.seconds.ago] )
  end

  def log_search params
    Search.log(params, request, current_user) if EOL.allowed_user_agent?(request.user_agent)
  end

  def update_logged_search params
    Search.update_log(params)
  end

  # Before filter
  def check_if_mobile
    # To-do if elsif elsif elsif.. This works but it's not really elegant!
    if mobile_agent_request? && !mobile_url_request? && !mobile_disabled_by_session?
      if params[:controller] == "taxa/overviews" && params[:taxon_id]
        redirect_to mobile_taxon_path(params[:taxon_id])
      elsif params[:controller] == "taxa/details" && params[:taxon_id]
        redirect_to mobile_taxon_details_path(params[:taxon_id])
      elsif params[:controller] == "taxa/media" && params[:taxon_id]
        redirect_to mobile_taxon_media_path(params[:taxon_id])
      else
        redirect_to mobile_contents_path
      end
    end
  end

  def mobile_agent_request?
    request.env["HTTP_USER_AGENT"] && request.env["HTTP_USER_AGENT"][/(iPhone|iPod|iPad|Android|IEMobile)/]
  end
  helper_method :mobile_agent_request?

  def mobile_url_request?
    request.request_uri.to_s.include? "\/mobile\/"
  end
  helper_method :mobile_url_request?

  def mobile_disabled_by_session?
    session[:mobile_disabled] && session[:mobile_disabled] == true
  end
  helper_method :mobile_disabled_by_session?


  def log_error_cleanly(e)
    logs = []
    logs << "*" * 76
    logs << "** #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    logs << "** EXCEPTION: (#{e.class.name}) #{e.message}"
    lines_shown = 0
    index = 0
    e.backtrace.map {|t| t.gsub(/#{RAILS_ROOT}/, '.')}.each do |trace|
      if trace =~ /\.?\/(usr|vendor).*:/
        logs << "       (#{trace})"
      else
        logs << "   #{trace}"
        lines_shown += 1
      end
      index += 1
      break if lines_shown > 12
    end
    logs << "   [...#{e.backtrace.length - index} more lines omitted]" if lines_shown > 12
    logs << "\n\n"
    logger.error logs.join("\n")
  end

  def resolve_common_session_errors
    begin
      if session[:language]
        session[:language].downcase
      end
      if session[:user]
        session[:user].language.iso_code
        logged_in_from_session?
        logged_in_from_cookie?
      end
      if cookies[:user_auth_token]
        User.find_by_remember_token(cookies[:user_auth_token])
      end
    rescue => e
      logger.warn "!! WARNING: found a problem (#{e.class.name}) in session: #{e.message}"
      session = nil
      cookies = nil
      flash = {}
      reset_session
      flash[:notice] = begin
                         I18n.t(:welcome_and_you_were_logged_out)
                       rescue
                         "There was a seious problem with your session and you have been logged out. Sorry."
                       end
    end
  end

end
