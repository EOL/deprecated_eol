# encoding: utf-8
class ApplicationController < ActionController::Base

  protect_from_forgery

  include ImageManipulation
  unless Rails.application.config.consider_all_requests_local
    rescue_from EOL::Exceptions::SecurityViolation, EOL::Exceptions::MustBeLoggedIn, with: :rescue_from_exception
    rescue_from ActionView::MissingTemplate, with: :rescue_from_exception
  end

  before_filter :original_request_params, except: [ :fetch_external_page_title ] # store unmodified copy of request params
  before_filter :global_warning, except: [ :fetch_external_page_title ]
  before_filter :check_user_agreed_with_terms, except: [ :fetch_external_page_title, :error ]
  before_filter :log_ip, except: [ :fetch_external_page_title, :error ]
  before_filter :set_locale, except: [ :fetch_external_page_title ]

  prepend_before_filter :keep_home_page_fresh

  helper :all

  helper_method :logged_in?, :current_url, :current_user, :current_language, :return_to_url, :link_to_item

  # If recaptcha is not enabled, then override the method to always return true
  unless $ENABLE_RECAPTCHA
    def verify_recaptcha
      true
    end
  end

  # Continuously display a warning message.  This is used for things like "System Shutting down at 15 past" and the
  # like.  And, yes, if there's a "real" error, they miss this message.  So what?
  # NOTE - you can clear this quickly with EolConfig.clear_global_site_warning
  def global_warning
    # NOTE (!) if you set this value and don't see it change in 10 minutes, CHECK YOUR SLAVE LAG. It reads from slaves.
    warning = EolConfig.global_site_warning
    flash.now[:error] = warning if warning
  end

  def set_locale
    I18n.locale = current_language.iso_639_1
  rescue
    I18n.locale = 'en' # Yes, I am hard-coding that because I don't want an error from Language.  Ever.
  end

  def log_ip
    return if params["action"] == "ping"
    user = logged_in? ? current_user.id : "[anon]"
    EOL.log("#{request.remote_ip} (#{user}): #{params.inspect}", prefix: "/") rescue nil
  end

  def allow_login_then_submit
    unless logged_in?
      # TODO: Can we delete the submitted data if the user doesn't login or signup?
      # TODO - can we generalize this and the associated code for handling POSTs before login?
      session[:submitted_data] = params
      # POST request should provide a submit_to URL so that we can redirect to the correct action with a GET.
      submit_to = params[:submit_to] || current_url
      respond_to do |format|
        format.html do
          flash[:notice] = I18n.t(:must_be_logged_in)
          redirect_to login_path(return_to: submit_to)
        end
        format.js do
          render partial: 'content/must_login', layout: false, locals: { return_to: submit_to }
        end
      end
    end
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

  # store a given URL (defaults to current) in case we need to redirect back later
  def store_location(url = url_for(controller: controller_name, action: action_name))
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

  def referred_url
    request.referer
  end

  def current_url(remove_querystring = true)
    if remove_querystring
      current_url = begin
                      URI.parse(request.url)
                    rescue => e
                      URI.parse(request.url.gsub(/[^-A-Za-z0-9_\/]/, ''))
                    ensure
                      ''
                    end
      current_url.query = nil
      current_url.to_s
    else
      request.url
    end
  end

  # Redirect to the URL stored by the most recent store_location call or to the passed default.
  def redirect_back_or_default(default_uri_or_active_record_instance = nil)
    back_uri = return_to_url || default_uri_or_active_record_instance
    store_location(nil)
    # If we've passed in an instance of active record, e.g. @user, we can redirect straight to it
    redirect_to back_uri and return if back_uri.is_a?(ActiveRecord::Base)
    back_uri = URI.parse(back_uri) rescue nil
    if back_uri.is_a?(URI::Generic) && back_uri.scheme.nil?
      # Assume it's a path and not a full URL, so make a full URL.
      back_uri = URI.parse("#{request.protocol}#{request.host_with_port}#{back_uri.to_s}")
    end
    # be sure we aren't returning to the login, register or logout page when logged in, or causing a loop
    # TODO - re-write this, it's not at all clear (and there are much better ways to express this, i.e.:
    # https://github.com/plataformatec/devise/wiki/How-To:-Redirect-back-to-current-page-after-sign-in,-sign-out,-sign-up,-update
    if ! back_uri.nil? && %w( http ).include?(back_uri.scheme) &&
      (! logged_in? || [logout_url, login_url, new_user_url].select{|url| back_uri.to_s.include?(url)}.blank?)
      back_uri.query = nil if back_uri.query =~ /oauth_provider/i
      back_uri = back_uri.to_s
      back_uri = CGI.unescape(back_uri)
    else
      back_uri = root_url(protocol: 'http')
    end
    redirect_to back_uri
  end

  # send user to the SSL version of the page (used in the account controller, can be used elsewhere)
  def redirect_to_ssl
    url_to_return = params[:return_to] ? CGI.unescape(params[:return_to]).strip : nil
    unless request.ssl? || local_request?
      if url_to_return && url_to_return[0...1] == '/'  #return to local url
        redirect_to protocol: "https://", return_to: url_to_return, method: request.method, status: :moved_permanently
      else
        redirect_to protocol: "https://", method: request.method, status: :moved_permanently
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
      render nothing: true
      return
    end

    ExternalLinkLog.log url, request, current_user

    redirect_to url

  end

  def keep_home_page_fresh
    # expire home page fragment caches after specified internal to keep it fresh
    if $CACHE_CLEARED_LAST.advance(hours: $CACHE_CLEAR_IN_HOURS) < Time.now
      expire_cache('home')
      $CACHE_CLEARED_LAST = Time.now()
    end
  end

  # expire a single non-species page fragment cache
  def expire_cache(page_name)
    expire_pages(ContentPage.find_all_by_page_name(page_name))
  end

  # just clear all fragment caches quickly
  def clear_all_caches
    Rails.cache.clear
    remove_cached_feeds
    # The docs warn about doing this, TODO - should we remove it?
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
    redirect_to protocol: "http://", status: :moved_permanently  if request.ssl?
  end

  # Language Object for the current request.  Stored as an instance variable to speed things up for multiple calls.
  def current_language
    @current_language ||= Language.find(session[:language_id]) rescue Language.default
  end

  def update_current_language(new_language)
    @current_language = new_language
    session[:language_id] = new_language.id
    I18n.locale = new_language.iso_639_1
  end

  # Deceptively simple... but note that memcached will only be hit ONCE per request because of the ||=
  def current_user
    @current_user ||= if session[:user_id]               # Try loading from session
                        User.cached(session[:user_id])   #   Will be nil if there was a problem...
                      elsif cookies[:user_auth_token]    # Try loading from cookie
                        load_user_from_cookie            #   Again, nil if there was a problem...
                      end
    if @current_user.nil?  # If the user didn't have a session, didn't have a cookie, OR if there was a problem:
      clear_any_logged_in_session
      @current_user = EOL::AnonymousUser.new(current_language)
    end
    @current_user
  end

  def set_current_user=(user)
    @current_user = user
  end

  def recently_visited_collections(collection_id = nil)
    session[:recently_visited_collections] ||= []
    session[:recently_visited_collections].unshift(collection_id)
    session[:recently_visited_collections] = session[:recently_visited_collections].uniq  # Ignore duplicates.
    session[:recently_visited_collections] = session[:recently_visited_collections][0..5] # Only keep six.
  end

  # Boot all users out when we don't want logins (note: preserves language):
  def clear_any_logged_in_session
    session[:user_id] = nil
  end

  # TODO: review the session-management code. It seems quite convoluted.
  def logged_in?
    # NOTE: the active check is to stop spammers from continuing to comment. Sigh.
    session[:user_id] && current_user.active?
  end

  def check_authentication
    must_log_in unless logged_in?
    return false
  end

  # TODO: I think we should prefer #check_authentication - remove this
  def must_be_logged_in(exception = nil)
    flash[:warning] = I18n.t(:must_be_logged_in)
    # NOTE - by default an exception (with no message) reports its class name as the message. We don't want that:
    flash[:warning] += " #{exception.message}" if exception && exception.message != exception.class.name
    session[:return_to] = request.url if params[:return_to].nil?
    redirect_to(login_path, return_to: params[:return_to])
  end


  # used as a before_filter on methods that you don't want users to see if they are logged in
  # such as the sessions#new, users#new, users#forgot_password etc
  def redirect_if_already_logged_in
    if logged_in?
      flash[:notice] = I18n.t(:destination_inappropriate_for_logged_in_users)
      return redirect_to(current_user) if params[:return_to].nil?
      return redirect_to(params[:return_to])
    end
  end

  def must_log_in
    respond_to do |format|
      format.html { store_location; redirect_to login_url }
      format.js   { render partial: 'content/must_login', layout: false }
    end
    return false
  end

  # call this method if someone is not supposed to get a controller or action when user accounts are disabled
  def accounts_not_available
    flash[:warning] =  I18n.t(:user_system_down)
    redirect_to root_url
  end

  def restrict_to_admins
    raise EOL::Exceptions::SecurityViolation.new(
      "User with ID=#{current_user.id} attempted to access an area (#{current_url}) or perform an action"\
      " that is restricted to EOL Administrators, and was disallowed.",
      :administrators_only) unless current_user.is_admin?
  end

  def restrict_to_admins_and_curators
    raise EOL::Exceptions::SecurityViolation.new(
      "User with ID=#{current_user.id} attempted to access an area (#{current_url}) or perform an action"\
      " that is restricted to EOL assistant curators and above, and was disallowed.",
      :min_assistant_curators_only) unless current_user.is_admin? || current_user.min_curator_level?(:assistant)
  end

  def restrict_to_admins_and_master_curators
    raise EOL::Exceptions::SecurityViolation.new(
      "User with ID=#{current_user.id} attempted to access an area (#{current_url}) or perform an action"\
      " that is restricted to EOL master curators and above, and was disallowed.",
      :admin_or_master_curators_only) unless current_user.is_admin? || current_user.min_curator_level?(:master)
  end

  def restrict_to_admins_and_cms_editors
    raise EOL::Exceptions::SecurityViolation.new(
      "User with ID=#{current_user.id} attempted to access an area (#{current_url}) or perform an action"\
      " that is restricted to EOL Administrators and CMS editors, and was disallowed.",
      :administrators_only) unless current_user.is_admin? || current_user.can?(:edit_cms)
  end

  def restrict_to_master_curators
    restrict_to_curators_of_level(:master)
  end

  def restrict_to_full_curators
    restrict_to_curators_of_level(:full)
  end

  def restrict_to_curators
    restrict_to_curators_of_level(:assistant)
  end

  # A user is not authorized for the particular controller/action:
  def access_denied(exception = nil)
    if exception.respond_to?(:flash_error)
      flash[:error] = [flash[:error], exception.flash_error].compact.join(' ').strip
    end
    flash[:error] ||= I18n.t('exceptions.security_violations.default')
    # Beware of redirect loops! Check we are not redirecting back to current URL that user can't access
    store_location(nil) if return_to_url && return_to_url.include?(current_url)
    store_location(referred_url) if referred_url && !return_to_url && !referred_url.include?(current_url)
    if logged_in?
      redirect_back_or_default
    else
      session[:return_to] = request.url if params[:return_to].nil?
      redirect_to login_path
    end
  end

  def not_yet_implemented
    flash[:warning] =  I18n.t(:not_yet_implemented_error)
    redirect_to request.referer ? :back : :default
  end

  def set_language
    language = Language.from_iso(params[:language]) rescue Language.default
    language ||= Language.default
    update_current_language(language)
    if logged_in?
      # Don't want to worry about validations on the user; language is simple.  Just update it:
      User.update_all({language_id: language.id}, {id: current_user.id})
      current_user.clear_cache
      current_user.expire_primary_index
      expire_fragment("sessions_#{current_user.id}")
    end
    redirect_to(params[:return_to].blank? ? root_url : params[:return_to])
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
    return if what === current_user
    watchlist = current_user.watch_collection
    if what.class == DataObject
      all_revision_ids = DataObject.find_all_by_guid_and_language_id(what.guid, what.language_id, select: 'id').map { |d| d.id }
      collection_item = CollectionItem.where(['collection_id = ? AND collected_item_id IN (?) AND collected_item_type = ?',
                                             watchlist.id, all_revision_ids, what.class.name]).first
    else
      collection_item = CollectionItem.where(['collection_id = ? AND collected_item_id = ? AND collected_item_type = ?', watchlist.id, what.id, what.class.name])
    end
    if collection_item.nil?
      collection_item = begin # We do not care if this fails.
        CollectionItem.create(annotation: options[:annotation], collected_item: what, collection_id: watchlist.id)
      rescue => e
        Rails.logger.error "** ERROR COLLECTING: #{e.message} FROM #{e.backtrace.first}"
        nil
      end
      if collection_item && collection_item.save
        return unless what.respond_to?(:summary_name) # Failsafe.  Most things should.
        flash[:notice] ||= ''
        flash[:notice] += ' '
        flash[:notice] += I18n.t(:item_added_to_watch_collection_notice,
                                 collection_name: self.class.helpers.link_to(watchlist.name,
                                                                                collection_path(watchlist)),
                                 item_name: what.summary_name)
        CollectionActivityLog.create(collection: watchlist, user_id: current_user.id,
                             activity: Activity.collect, collection_item: collection_item)
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

  # clear the cached activity logs on homepage
  def clear_cached_homepage_activity_logs
    if Rails.cache
      Language.find_active.each do |language|
        expire_fragment(action: 'index', controller: "content",
          action_suffix: "activity_#{language}_data_#{EolConfig.data?}")
      end
    end
  end

  # TODO - review. This seems quite convoluted; it's certainly obfuscated.
  def rescue_from_exception(exception = env['action_dispatch.exception'])
    rescue_action_in_public(exception)
  end

  # TODO - this doesn't belong in a controller. Move it to a lib or a model.
  def fetch_external_page_title
    data = {}
    success = nil
    response_title = nil
    is_allowable_redirect = nil
    redirect=nil
    I18n.locale = params['lang'] if params['lang']
    begin
      url = params[:url]
      url = "http://" + url unless url =~ /^[a-z]{3,5}:\/\//i
      response = Net::HTTP.get_response(URI.parse(url))
      if (response.code == "301" || response.code == "302" || response.code == "303") && response.kind_of?(Net::HTTPRedirection)
        is_allowable_redirect = true if EOLWebService.in_allowable_redirection_domains((URI.parse(url)))
        response = Net::HTTP.get_response(URI.parse(response['location']))
      end
      if response.code == "200"
        response_body = response.body.force_encoding('utf-8') # NOTE the force, here... regex fails on some pages w/o
        if response['Content-Encoding'] == "gzip"
          response_body = ActiveSupport::Gzip.decompress(response.body)
        end
        success = true
        if matches = response_body.match(/<title>(.*?)<\/title>/ium)
          response_title = matches[1].strip
        end
      elsif is_allowable_redirect &&(response.code == "301" || response.code == "302" || response.code == "303") && response.kind_of?(Net::HTTPRedirection)
        redirect = true
      end
    rescue Exception => e
    end
    if success
      if response_title
        data['exception'] = false
        data['message'] = response_title
      else
        data['exception'] = true
        data['message'] = I18n.t(:unable_to_determine_title)
      end
    elsif redirect
        data['exception'] = true
        data['message'] = I18n.t(:redirect_url_ok_title_unavailable)
    else
      data['exception'] = true
      data['message'] = I18n.t(:url_not_accessible)
    end
    render text: data.to_json
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
    status_code     = ActionDispatch::ExceptionWrapper.new(env, exception).status_code
    response_code   = ActionDispatch::ExceptionWrapper.rescue_responses[exception.class.name]
    if exception.class == ActionView::MissingTemplate
      status_code = 404
      response_code = :not_found
    end
    render_exception_response(exception, response_code, status_code)
    # Log to database
    if ! $IGNORED_EXCEPTIONS.include?(exception.to_s) &&
       ! $IGNORED_EXCEPTION_CLASSES.include?(exception.class.to_s)
      user_id = logged_in? ? current_user.id : 0
      EOL.log("ERROR: #{env['REQUEST_URI']} (user #{user_id})", prefix: "*")
      EOL.log_error(exception)
      # Notify New Relic about exception
      NewRelic::Agent.notice_error(exception) if $PRODUCTION_MODE
    end
  end

  # custom method to render an appropriate response to an exception
  def render_exception_response(exception, response_code, status_code)
    case response_code
    when :unauthorized # This is caused by MustBeLoggedIn, actually...
      logged_in? ? access_denied(exception) : must_be_logged_in(exception)
    when :forbidden
      access_denied(exception)
    when :not_implemented
      not_yet_implemented
    else
      respond_to do |format|
        format.html do
          @error_page_title = I18n.t("error_#{status_code}_page_title", default: [:error_default_page_title, "Error."])
          @status_code = status_code
          render layout: 'errors', template: 'content/error', status: status_code
        end
        format.js do
          render layout: false, template: 'content/error', status: status_code
        end
        format.all do
          @error_page_title = I18n.t("error_#{status_code}_page_title", default: [:error_default_page_title, "Error."])
          @status_code = status_code
          render layout: 'errors', template: 'content/error', status: status_code, formats: 'html', content_type: Mime::HTML.to_s
        end
      end
    end
  end

  # Defines the scope of the controller and action method (i.e. view path) for using in i18n calls
  # Used by meta tag helper methods
  def controller_action_scope
    @controller_action_scope ||= controller_path.split("/") << action_name
  end
  helper_method :controller_action_scope

  # Defines base variables for use in scoped i18n calls, used by meta tag helper methods
  def scoped_variables_for_translations
    @scoped_variables_for_translations ||= {
      default: '',
      scope: controller_action_scope }.freeze # frozen to force use of dup, otherwise wrong vars get sent to i18n
  end

  def meta_data(title = meta_title, description = meta_description, keywords = meta_keywords)
    @meta_data ||=  { title: [
                      @home_page ? I18n.t(:meta_title_site_name) : title.presence,
                      @rel_canonical_href_page_number ? I18n.t(:pagination_page_number, number: @rel_canonical_href_page_number) : nil,
                      @home_page ? title.presence : I18n.t(:meta_title_site_name)
                    ].compact.join(" - ").strip,
                  description: description,
                  keywords: keywords
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
    @meta_description ||= t("#{scoped_variables_for_translations[:scope].join(".")}.meta_description",
                         scoped_variables_for_translations.except(:scope))
  end

  def meta_keywords
    @meta_keywords ||= t("#{scoped_variables_for_translations[:scope].join(".")}.meta_keywords",
                         scoped_variables_for_translations.except(:scope))
  end

  def tweet_data(text = nil, hashtags = nil, lang = I18n.locale.to_s, via = $TWITTER_USERNAME)
    return @tweet_data unless @tweet_data.blank?
    if text.nil?
      translation_vars = scoped_variables_for_translations.dup
      translation_vars[:default] = meta_title if translation_vars[:default].blank?
      text = I18n.t(:tweet_text, translation_vars)
    end
    @tweet_data = {lang: lang, via: via, hashtags: hashtags,
                   text: text}.delete_if{ |k, v| v.blank? }
  end
  helper_method :tweet_data

  def meta_open_graph_data
    @meta_open_graph_data ||= {
      'og:url' => meta_open_graph_url,
      'og:site_name' => I18n.t(:encyclopedia_of_life),
      'og:type' => 'website', # TODO: we may want to extend to other types depending on the page see http://ogp.me/#types
      'og:title' => meta_data[:title],
      'og:description' => meta_data[:description],
      'og:image' => (!meta_open_graph_image_url.blank? && meta_open_graph_image_url != '#') ? meta_open_graph_image_url : view_context.image_url('v2/logo_open_graph_default.png')
    }.delete_if{ |k, v| v.blank? }
  end
  helper_method :meta_open_graph_data

  def meta_open_graph_url
    @meta_open_graph_url ||= request.url
  end

  def meta_open_graph_image_url
    @meta_open_graph_image_url ||= nil
  end

  # You should pass in :for (the object page you're on), :paginated (a collection of WillPaginate results), and
  # :url_method (to the object's page--don't use *_path, use *_url).
  def set_canonical_urls(options = {})
    page = rel_canonical_href_page_number(options[:paginated])
    parameters = []
    if options[:for].is_a? Hash
      parameters << options[:for].merge(page: page)
    else
      parameters << options[:for] if options[:for]
      parameters << {page: page}
    end
    @rel_canonical_href = self.send(options[:url_method], *parameters)
    @rel_prev_href = rel_prev_href_params(options[:paginated]) ?
      self.send(options[:url_method], @rel_prev_href_params) : nil
    @rel_next_href = rel_next_href_params(options[:paginated]) ?
      self.send(options[:url_method], @rel_next_href_params) : nil
  end

  # rel canonical only cares about page param for paginated records with current_page greater than 1
  def rel_canonical_href_page_number(records)
    @rel_canonical_href_page_number ||= records.is_a?(WillPaginate::Collection) && records.current_page > 1 ?
      records.current_page : nil
  end

  # rel prev href needs the current request params with current page number swapped out for the number of the
  # previous page; return nil if there is no previous page
  # NOTE - original_params is *never* passed in.
  def rel_prev_href_params(records, original_params = original_request_params.clone)
    @rel_prev_href_params ||= records.is_a?(WillPaginate::Collection) && records.previous_page ?
      original_params.merge({ page: records.previous_page }) : nil
  end

  # rel next href needs the current request params with current page number swapped out for the number of the next page
  # return nil if there is no next page
  def rel_next_href_params(records, original_params = original_request_params.clone)
    @rel_next_href_params ||= records.is_a?(WillPaginate::Collection) && records.next_page ?
      original_params.merge({ page: records.next_page }) : nil
  end

  # Set in before filter and frozen so we have an unmodified copy of request params for use in rel link tags
  def original_request_params
    return @original_request_params if @original_request_params
    if params[:controller] == 'search' && params[:action] == 'index' && params[:id]
      if params[:q].blank?
        params["q"] = params["id"]
      end
      params.delete("id")
    end
    @original_request_params ||= params.clone.freeze # frozen because we don't want @original_request_params to be modified
  end

  def page_title(scope = controller_action_scope)
    @page_meta.try(:title) || @page_title ||
      I18n.t(:page_title, scope: scope, default: "")
  end
  helper_method :page_title

  def page_subtitle
    @page_meta.try(:subtitle) || @page_subtitle || ""
  end
  helper_method :page_subtitle

  def page_description(scope = controller_action_scope)
    @page_meta.try(:description) || @page_description ||
      I18n.t(:page_description, scope: scope, default: "")
  end
  helper_method :page_description

  # NOTE - these two are TOTALLY DUPLICATED from application_helper, because I CAN'T GET COLLECTIONS TO WORK.  WTF?!?
  def link_to_item(item, options = {})
    case item
    when Collection
      collection_url(item, options)
    when Community
      community_url(item, options)
    when DataObject
      data_object_url(item.latest_published_version_in_same_language || item, options)
    when User
      user_url(item, options)
    when TaxonConcept
      taxon_url(item, options)
    when UserAddedData
      options.merge!(anchor: item.anchor)
      taxon_data_url(item.taxon_concept, options)
    when DataPointUri
      options.merge!(anchor: item.anchor)
      taxon_data_url(item.taxon_concept, options)
    else
      raise EOL::Exceptions::ObjectNotFound
    end
  end
  def link_to_newsfeed(item, options = {})
    case item
    when Collection
      collection_newsfeed_url(item, options)
    when Community
      community_newsfeed_url(item, options)
    when DataObject
      data_object_url(item.latest_published_version_in_same_language || item, options)
    when User
      user_newsfeed_url(item, options)
    when TaxonConcept
      if options[:taxon_updates] # Sometimes you want to go to the long activity view for taxa...
        taxon_updates_url(item, options.delete(:taxon_updates))
      else
        taxon_url(item, options)
      end
    when UserAddedData
      options.merge!(anchor: item.anchor)
      taxon_data_url(item.taxon_concept, options)
    when DataPointUri
      options.merge!(anchor: item.anchor)
      taxon_data_url(item.taxon_concept, options)
    else
      raise EOL::Exceptions::ObjectNotFound
    end
  end

private

  # NOTE - levels allowed are :assistant, :full and :master. (You may need this for the i18n YAML.)
  def restrict_to_curators_of_level(level)
    raise EOL::Exceptions::SecurityViolation.new(
      "User with ID=#{current_user.id} attempted to access an area (#{current_url}) or perform an action"\
      " that is restricted to EOL #{level} curators and above, and was disallowed.",
      "min_#{level}_curators_only", :this_action_requires_higher_curation_level) unless current_user.min_curator_level?(level)
  end

  # Currently only used by collections and content controllers to log in users coming from iNaturalist
  # TODO: Allow for all URLs except be sure not to interfere with EOL registration or login
  def login_with_open_authentication
    # TODO we want to check for authorization behind the scenes without making the user do anything,
    # but it looks like that is not possible from the server-side - at least not with Facebook...
    # might be possible with AJAX.
    return unless params[:oauth_provider]
    unless logged_in?
      if current_url == return_to_url
        # FIXME: since we are redirecting the current page e.g. collections show is not stored in browser
        # history so if a user tries to use their back button during authorization, then they will skip the
        # collection page and go back to the referring page e.g. iNat. So the problem is the user would not
        # be able to view the collection page. This is more likely with Yahoo! as they don't have a cancel
        # button on their authorization screen. Band-aid fix is to compare the current_url with the session
        # return_to_url, if they are the same then don't redirect to login - they will be the same the second
        # time a user clicks on the link from the referrer. Alternative solution might be to do all this on
        # the client side with AJAX... but first things first.
        session.delete_if{|k,v| k.to_s.match /^[a-z]+(_request_token_(token|secret)|_oauth_state)$/i}
        store_location(nil)
      else
        store_location(current_url)
        redirect_to login_url(oauth_provider: params[:oauth_provider].downcase) and return
      end
    end
    redirect_to current_url # redirecting to remove oauth parameters from the URL
    # TODO: check inat not sending us params other than oauth_provider
  end

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
    FileUtils.rm_rf(Dir.glob(Rails.root.join(Rails.public_path, 'feeds', '*')))
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

  def expire_pages(pages)
    if pages.length > 0
      Language.find_active.each do |language|
        pages.each do |page|
          if page.class == ContentPage
            expire_fragment(controller: '/content', part: "#{page.id.to_s }_#{language.iso_639_1}")
            expire_fragment(controller: '/content',
                            part: "#{page.page_url.underscore_non_word_chars.downcase}_#{language.iso_639_1}")
            page.clear_all_caches rescue nil # TODO - still having some problem with ContentPage, not sure why.
          else
            expire_fragment(controller: '/content', part: "#{page}_#{language.iso_639_1}")
          end
          if page.class == ContentPage && page.page_url == 'home'
            Hierarchy.find_each do |h|
              expire_fragment(controller: '/content', part: "home_#{language.iso_639_1}_#{h.id.to_s}") # this is because the home page fragment is dependent on the user's selected hierarchy entry ID, unlike the other content pages
            end
          end
        end
      end
    end
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
        redirect_to mobile_taxon_path(params[:taxon_id]), status: :moved_permanently
      elsif params[:controller] == "taxa/details" && params[:taxon_id]
        redirect_to mobile_taxon_details_path(params[:taxon_id]), status: :moved_permanently
      elsif params[:controller] == "taxa/media" && params[:taxon_id]
        redirect_to mobile_taxon_media_path(params[:taxon_id]), status: :moved_permanently
      else
        redirect_to mobile_contents_path, status: :moved_permanently
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

  def load_user_from_cookie
    begin
      user = User.find_by_remember_token(cookies[:user_auth_token]) rescue nil
      session[:user_id] = user.id # The cookie will persist, but now we can log in directly from the session.
      user
    rescue ActionController::SessionRestoreError => e
      reset_session
      cookies.delete(:user_auth_token)
      Rails.logger.warn "!! Rescued a corrupt cookie."
      nil
    end
  end

  # TODO: ideally, this would use the class associated with the controller
  # calling it. As it happens, we don't really have to worry about that now that
  # we did away with the two databases... but it's worth being aware that
  # anything in the yielded block could fail if it calls logging (untested).
  def with_master_if_curator(&block)
    if current_user.try(:is_curator?)
      TaxonConcept.with_master do
        yield
      end
    else
      yield
    end
  end

end
