require 'uri'
ContentPage # TODO - figure out why this fails to autoload.  Look at http://kballcodes.com/2009/09/05/rails-memcached-a-better-solution-to-the-undefined-classmodule-problem/

class ApplicationController < ActionController::Base

  # Map custom exceptions to default response codes
  ActionController::Base.rescue_responses.update(
    'EOL::Exceptions::MustBeLoggedIn'             => :unauthorized,
    'EOL::Exceptions::SecurityViolation'          => :forbidden,
    'EOL::Exceptions::Pending'                    => :not_implemented,
    'OpenURI::HTTPError'                          => :bad_request
  )

  filter_parameter_logging :password
  include ContentPartnerAuthenticationModule # TODO -seriously?!?  You want all that cruft available to ALL controllers?!
  include ImageManipulation

  # If recaptcha is not enabled, then override the method to always return true
  unless $ENABLE_RECAPTCHA
    def verify_recaptcha
      true
    end
  end

  before_filter :original_request_params # store unmodified copy of request params
  before_filter :global_warning
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
    # using SiteConfigutation over an environment constant DOES require a query for EVERY REQUEST
    # but the table is tiny (<5 rows right now) and the coloumn is indexed. But it also gives us the flexibility
    # to display or remove a message within seconds which I think is worth it
    parameter = SiteConfigurationOption.find_by_parameter('global_site_warning')
    if parameter && parameter.value
      flash.now[:error] = parameter.value
    end
  end

  def set_locale
    begin
      I18n.locale = current_user.language_abbr
    rescue
      I18n.locale = 'en' # Yes, I am hard-coding that because I don't want an error from Language.  Ever.
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
        redirect_to :protocol => "https://", :return_to => url_to_return, :method => request.method, :status => :moved_permanently
      else
        redirect_to :protocol => "https://", :method => request.method, :status => :moved_permanently
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
      redirect_to "http://" + request.host + request.request_uri, :status => :moved_permanently
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
    redirect_to :protocol => "http://", :status => :moved_permanently  if request.ssl?
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

  def recently_visited_collections(collection_id = nil)
    session[:recently_visited_collections] = [] if session[:recently_visited_collections].nil?
    unless collection_id.nil?
      session[:recently_visited_collections].delete_if{ |rvc| rvc == collection_id || rvc == nil }
      session[:recently_visited_collections] << collection_id
      session[:recently_visited_collections].shift if session[:recently_visited_collections].length > 6
    end
    return session[:recently_visited_collections]
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
    flash_and_redirect_back(I18n.t(:you_are_not_authorized_to_perform_this_action), 403)
  end

  def not_yet_implemented
    flash[:warning] =  I18n.t(:not_yet_implemented_error)
    redirect_to request.referer ? :back : :default
  end

  def flash_and_redirect_back(msg, status_code)
    flash[:error] = msg
    respond_to do |format|
      format.html { redirect_back_or_default }
      format.js { render :text => warning, :status => status_code }
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

  # Ensure that the user has this in their watch_colleciton, so they will get replies in their newsfeed:
  def auto_collect(what, options = {})
    options[:annotation] ||= I18n.t(:user_left_comment_on_date, :username => current_user.full_name,
                                    :date => I18n.l(Time.now, :format => :long))
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
      taxon_url(item)
    else
      raise EOL::Exceptions::ObjectNotFound
    end
  end

  # clear the cached activity logs on homepage
  def clear_cached_homepage_activity_logs
    $CACHE.delete('homepage/activity_logs_expiration') if $CACHE
  end

protected

  # Overrides ActionController::Rescue local_request? to allow custom configuration of which IP addresses
  # are considered to be local requests (versus public) and therefore get full error messages. Modify
  # $LOCAL_REQUEST_ADDRESSES values to toggle between public and local error views when using a local IP.
  def local_request?
    return false unless $LOCAL_REQUEST_ADDRESSES.is_a? Array
    $LOCAL_REQUEST_ADDRESSES.any?{ |local_ip| request.remote_addr == local_ip && request.remote_ip == local_ip }
  end

  # Overrides ActionController::Rescue rescue_action_in_public to render custom views instead of static HTML pages
  # public/404.html and public/500.html. Static pages are still used if exception prevents reaching controller
  # e.g. see ActionController::Failsafe which catches e.g. MySQL exceptions such as database unknown
  def rescue_action_in_public(exception)

    resolve_common_session_errors

    # exceptions in views are wrapped by ActionView::TemplateError and will return 500 response
    # if we use the original_exception we may get a more meaningful response code e.g. 404 for ActiveRecord::RecordNotFound
    if exception.is_a?(ActionView::TemplateError) && defined?(exception.original_exception)
      response_code = response_code_for_rescue(exception.original_exception)
    else
      response_code = response_code_for_rescue(exception)
    end
    render_exception_response(exception, response_code)

    # Log to database
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
    # Notify New Relic about exception
    NewRelic::Agent.notice_error(exception) if $PRODUCTION_MODE
  end

  # custom method to render an appropriate response to an exception
  def render_exception_response(exception, response_code)
    case response_code
    when :unauthorized
      logged_in? ? access_denied : must_be_logged_in
    when :forbidden
      access_denied
    when :not_implemented
      not_yet_implemented
    else
      status = interpret_status(response_code) # defaults to "500 Unknown Status" if response_code is not recognized
      status_code = status[0,3]
      respond_to do |format|
        format.html do
          @error_page_title = I18n.t("error_#{status_code}_page_title", :default => [:error_default_page_title, "Error."])
          @status_code = status_code
          render :layout => 'v2/errors', :template => 'content/error', :status => status_code
        end
        format.js do
          render :layout => false, :template => 'content/error', :status => status_code
        end
        format.all { render :text => status, :status => status_code }
      end
    end
  end

  # Defines the scope of the controller and action method (i.e. view path) for using in i18n calls
  # Used by meta tag helper methods
  def controller_action_scope
    @controller_action_scope ||= controller_path.split("/") << action_name
  end

  # Defines base variables for use in scoped i18n calls, used by meta tag helper methods
  def scoped_variables_for_translations
    @scoped_variables_for_translations ||= {
      :default => '',
      :scope => controller_action_scope }.freeze # frozen to force use of dup, otherwise wrong vars get sent to i18n
  end

  def meta_data(title = meta_title, description = meta_description, keywords = meta_keywords)
    @meta_data ||= {:title => [
                      title.presence,
                      @rel_canonical_href_page_number ? I18n.t(:pagination_page_number, :number => @rel_canonical_href_page_number) : nil,
                      I18n.t(:meta_title_suffix)].compact.join(" - ").strip,
                    :description => description,
                    :keywords => keywords
                   }.delete_if{ |k, v| v.nil? }
  end
  helper_method :meta_data

  def meta_title
    return @meta_title unless @meta_title.blank?
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:default] = @page_title if !@page_title.nil? && translation_vars[:default].blank?
    @meta_title = t(".meta_title", translation_vars)
  end

  def meta_description
    @meta_description ||= t(".meta_description", scoped_variables_for_translations.dup)
  end

  def meta_keywords
    @meta_keywords ||= t(".meta_keywords", scoped_variables_for_translations.dup)
  end

  def tweet_data(text = nil, hashtags = nil, lang = I18n.locale.to_s, via = $TWITTER_USERNAME)
    return @tweet_data unless @tweet_data.blank?
    if text.nil?
      translation_vars = scoped_variables_for_translations.dup
      translation_vars[:default] = meta_title if translation_vars[:default].blank?
      text = I18n.t(:tweet_text, translation_vars)
    end
    @tweet_data = {:lang => lang, :via => via, :hashtags => hashtags,
                   :text => text}.delete_if{ |k, v| v.blank? }
  end
  helper_method :tweet_data

  def meta_open_graph_data
    @meta_open_graph_data ||= {
      'og:url' => meta_open_graph_url,
      'og:site_name' => I18n.t(:encyclopedia_of_life),
      'og:type' => 'website', # TODO: we may want to extend to other types depending on the page see http://ogp.me/#types
      'og:title' => meta_data[:title],
      'og:description' => meta_data[:description],
      'og:image' => meta_open_graph_image_url || view_helper_methods.image_url('v2/logo_open_graph_default.png')
    }.delete_if{ |k, v| v.blank? }
  end
  helper_method :meta_open_graph_data

  def meta_open_graph_url
    @meta_open_graph_url ||= request.url
  end

  def meta_open_graph_image_url
    @meta_open_graph_image_url ||= nil
  end

  # rel canonical only cares about page param for paginated records with current_page greater than 1
  def rel_canonical_href_page_number(records)
    @rel_canonical_href_page_number ||= records.is_a?(WillPaginate::Collection) && records.current_page > 1 ?
      records.current_page : nil
  end

  # rel prev href needs the current request params with current page number swapped out for the number of the previous page
  # return nil if there is no previous page
  def rel_prev_href_params(records, original_params = original_request_params.clone)
    @rel_prev_href_params ||= records.is_a?(WillPaginate::Collection) && records.previous_page ?
      original_params.merge({ :page => records.previous_page }) : nil
  end

  # rel next href needs the current request params with current page number swapped out for the number of the next page
  # return nil if there is no next page
  def rel_next_href_params(records, original_params = original_request_params.clone)
    @rel_next_href_params ||= records.is_a?(WillPaginate::Collection) && records.next_page ?
      original_params.merge({ :page => records.next_page }) : nil
  end

  # Set in before filter and frozen so we have an unmodified copy of request params for use in rel link tags
  def original_request_params
    @original_request_params ||= params.clone.freeze # frozen because we don't want @original_request_params to be modified
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
        redirect_to mobile_taxon_path(params[:taxon_id]), :status => :moved_permanently
      elsif params[:controller] == "taxa/details" && params[:taxon_id]
        redirect_to mobile_taxon_details_path(params[:taxon_id]), :status => :moved_permanently
      elsif params[:controller] == "taxa/media" && params[:taxon_id]
        redirect_to mobile_taxon_media_path(params[:taxon_id]), :status => :moved_permanently
      else
        redirect_to mobile_contents_path, :status => :moved_permanently
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
                         "There was a serious problem with your session and you have been logged out. Sorry."
                       end
    end
  end

end
