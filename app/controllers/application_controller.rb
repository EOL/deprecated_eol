require 'uri'
ContentPage # TODO - figure out why this fails to autoload.  Look at http://kballcodes.com/2009/09/05/rails-memcached-a-better-solution-to-the-undefined-classmodule-problem/

class ApplicationController < ActionController::Base

  include ContentPartnerAuthenticationModule # TODO -seriously?!?  You want all that cruft available to ALL controllers?!

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

  prepend_before_filter :redirect_to_http_if_https
  prepend_before_filter :set_session
  before_filter :clear_any_logged_in_session unless $ALLOW_USER_LOGINS
  before_filter :set_user_settings

  helper :all

  helper_method :logged_in?, :current_url, :current_user, :return_to_url, :current_agent, :agent_logged_in?,
    :allow_page_to_be_cached?
  around_filter :set_current_language

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
    respond_to do |type|
      type.html { render :layout => 'main', :template => "content/missing", :status => 404} # status may be redundant
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
    respond_to do |type|
     type.html { render :layout => 'main', :template => "content/error"}
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
      session[:return_to] = url
  end

  # retrieve the stored URL that we want to go back to
  def return_to_url
    session[:return_to] || root_url
  end
  
  # Set the page expertise and vetted defaults, get from querystring, update the session with this value if found
  def set_user_settings
    expertise = params[:expertise] if ['novice', 'middle', 'expert'].include?(params[:expertise])
    if !expertise.blank? && current_user.expertise != expertise
      alter_current_user do |user|
        user.expertise = expertise unless expertise.nil?
      end
    end
    vetted = EOLConvert.to_boolean(params[:vetted])
    if !vetted.blank? && current_user.vetted != vetted
      alter_current_user do |user|
        user.vetted = vetted unless vetted.blank?
      end
    end
  end
  
  def valid_return_to_url
    return_to_url != nil && return_to_url != login_url && return_to_url != register_url && return_to_url != logout_url && !url_for(:controller => 'content_partner', :action => 'login', :only_path => true).include?(return_to_url)
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

  # expire the header and footer caches
  def expire_menu_caches(page = nil)
    list = ['top_nav', 'footer', 'exemplars'] # TODO - i18n
    unless page.nil?
      list << page.id
    end
    expire_pages(list)
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
    Thread.new do
      begin
        expire_taxa(DataObject.find(data_object_id).get_taxon_concepts(:published => :strict))
      rescue Exception => e
        if e.to_s != "Taxon concept must have at least one hierarchy entry"
          raise e
        end
      end
    end
  end

  # NOTE: If you want to expire it's ancestors, too, use #expire_taxa.
  # TODO: Rather than having to iterate through all of these alternative key names and expire them whether or not they
  # actually exist, we should have a list (in memcached) of all of the keys associated for a particular page.  Then, we can
  # read that list (ie: "taxa/memcached_keys") and iterate over the array of keys that *actually exist* and remove them.
  def expire_taxon_concept(taxon_concept_id, params = {})
    raise 'Expiring nothing' if taxon_concept_id.blank?
    raise "Not a number: #{taxon_concept_id}" if taxon_concept_id.to_i == 0
    raise "Taxon Concept #{taxon_concept_id} does not exist" unless TaxonConcept.exists?(taxon_concept_id)
    browsable_hierarchy_ids = Hierarchy.browsable_by_label.map {|h| h.id.to_s }
    Language.find_active.each do |language|
      %w{middle expert}.each do |expertise| # NOTE - this used to include novice, but we don't use it anymore.
        %w{true false}.each do |vetted|
          %w{text}.each do |default_taxonomic_browser| # NOTE - this used to include flash, but we don't use it anymore.
            [nil.to_s, browsable_hierarchy_ids].flatten.each do |default_hierarchy_id|
              %w{true false}.each do |can_curate|
                part_name = 'page_' + taxon_concept_id.to_s +
                                '_' + language.iso_639_1 +
                                '_' + expertise +
                                '_' + vetted +
                                '_' + default_taxonomic_browser +
                                '_' + default_hierarchy_id +
                                '_' + can_curate
                expire_fragment(:controller => '/taxa', :part => part_name)
              end
            end
          end
        end
      end
    end
  end

  # check if the requesting IP address is allowed (used to resrict methods to specific IPs, such as MBL/EOL IPs)
  def allowed_request
    !((request.remote_ip =~ /127.0.0.1/).nil? && (request.remote_ip =~ /128.128./).nil? && (request.remote_ip =~ /10.19./).nil?)
  end


  # send user back to the non-SSL version of the page
  def redirect_back_to_http
    redirect_to :protocol => "http://" if request.ssl?
  end

  # check if user is curator and display the curator documentation pages from curator central with the left sidebar navigation
  def redirect_if_curator
    if current_user.is_curator?
      redirect_pages = ["curator_central", "curator_todo", "curation", "curate_wiki", "curation_standards"]
      redirect_to :controller => :curators, :action => :index, :id => params[:id] if redirect_pages.include? params[:id]
    end
  end
  
  # default new user when we don't have a logged in user
  def create_new_user
    session[:user_id] = nil
    User.create_new(:remote_ip => request.remote_ip)
  end

  def reset_session
    create_new_user
    current_agent = nil
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
    user.save! if logged_in?
    $CACHE.delete("users/#{session[:user_id]}")
    set_current_user(user)
  end

  # this method is used as a before_filter when user logins are disabled to ensure users who may have had a previous
  # session before we switched off user logins is booted out
  def clear_any_logged_in_session
    reset_session if logged_in?
  end
  

  ###########
  # AUTHENTICATION/AUTHORIZATION METHODS

  # check to see if we have a logged in user
  def logged_in?
    return(logged_in_from_session? || logged_in_from_cookie?)
  end
  
  def logged_in_from_session?
    !!session[:user_id]
  end
  
  def logged_in_from_cookie?
    user = cookies[:user_auth_token] && User.find_by_remember_token(cookies[:user_auth_token])
    if user && user.remember_token?
      cookies[:user_auth_token] = { :value => user.remember_token, :expires => user.remember_token_expires_at }
      set_logged_in_user(user)
      return true
    else
      return false
    end    
  end

  def check_authentication
    must_log_in unless logged_in?
    return false
  end

  def is_user_admin?
    return current_user.roles.include?(Role.find_by_title("Administrator"))
  end

  # Returns true if the given user (or currently logged in user if not provided) has curator permissions
  # for the given TaxonConcept or any parent thereof.
  def is_curator?(tc, user = nil)
    user = current_user if user.nil?
    return false if tc.nil? or user.nil?
    return false unless tc.is_a?(TaxonConcept) and user.is_a?(User)
    user.can_curate? tc
  end
  alias is_curator is_curator?

 def permission_denied
   flash[:warning] = "You are not authorized to perform this action."[]
   return redirect_to(root_url)
 end

 def permission_granted
 end

  # used as a before_filter on methods that you don't want users to see if they are logged in (such as the login or register page)
  def go_to_home_page_if_logged_in
    redirect_to(root_url) if logged_in?
  end

  def must_log_in
    store_location
    redirect_to login_url
    return false
  end

  # call this method if someone is not supposed to get a controller or action when user accounts are disabled
  def accounts_not_available
    flash[:warning] = "We apologize, but the user registration system is not currently available.  Please try again later."[:user_system_down]
    redirect_to root_url
  end

  # A user is not authorized for the particular controller based on the rights for the roles they are in
  def access_denied
    flash.now[:warning] = "You are not authorized to perform this action."[]
    request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to root_url)
  end

  # Set the current language
  def set_language
    language = params[:language].to_s
    languages = Gibberish.languages.map { |l| l.to_s } + ["en"]
    if languages.include?(language)
      alter_current_user do |user|
        user.language = Language.find_by_iso_639_1(language)
      end
    end
    return_to = (params[:return_to].blank? ? root_url : params[:return_to])
    redirect_to return_to
  end

  # pulled over from Rails core helper file so it can be used in controllers as well
  def escape_javascript(javascript)
     (javascript || '').gsub('\\', '\0\0').gsub('</', '<\/').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
  end

  def set_session_hierarchy_variable
    hierarchy_id = current_user.default_hierarchy_valid? ? current_user.default_hierarchy_id : Hierarchy.default.id
    secondary_hierarchy_id = current_user.secondary_hierarchy_id rescue nil
    @session_hierarchy = Hierarchy.find(hierarchy_id)
    @session_secondary_hierarchy = secondary_hierarchy_id.nil? ? nil : Hierarchy.find(secondary_hierarchy_id)
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
    expire_page( :controller => '/content', :action => 'tc_api' )
  end

  # Rails cache (memcached, probably) version of the user, by id: 
  def cached_user
    User # KNOWN BUG (in Rails): if you end up with "undefined class/module" errors in a fetch() call, you must call
         # that class beforehand.
    $CACHE.fetch("users/#{session[:user_id]}") { User.find(session[:user_id]) }
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
            # NOTE - the / is needed before content, or administrator pages will use administrator/content.  Silly.
            expire_fragment(:controller => '/content', :part => "#{page.id}_#{language.iso_639_1}")
            page.clear_all_caches rescue nil # TODO - still having some problem with ContentPage, not sure why.
            if page.page_url == 'home'
              # this is because the home page fragment is dependent on the user's selected hierarchy entry ID,
              # unlike the other content pages:
              Hierarchy.all.each do |h|
                expire_fragment(:controller => '/content', :part => "home_#{language.iso_639_1}_#{h.id}")
              end
            end
          else
            expire_fragment(:controller => '/content', :part => "#{page}_#{language.iso_639_1}")
          end
        end
      end
    end
  end

  def clear_old_sessions
    CGI::Session::ActiveRecordStore::Session.destroy_all( ['updated_at <?', $SESSION_EXPIRY_IN_SECONDS.seconds.ago] )
  end

  # Set language around filter
  def set_current_language
    current_user.language = Language.english if current_user.language.nil? or current_user.language_abbr == ""
    Gibberish.use_language(current_user.language_abbr) { yield }
  end

  def log_search params
    Search.log(params, request, current_user) if EOL.allowed_user_agent?(request.user_agent)
  end

  def update_logged_search params
    Search.update_log(params)
  end

end
