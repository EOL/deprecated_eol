require 'uri'

# TODO - this deosn't belong here.  Move this to lib/extensions.rb
# make the sanitize_sql protected method in ActiveRecord base available as a public method called "eol_escape_sql"
module ActiveRecord
  class Base
    def self.eol_escape_sql(sql)
      sanitize_sql(sql)
    end
  end
end

class ApplicationController < ActionController::Base

  include ContentPartnerAuthenticationModule

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

  prepend_before_filter :set_session
  before_filter :clear_any_logged_in_session unless $ALLOW_USER_LOGINS
  before_filter :set_user_settings

  helper :all

  helper_method :logged_in?, :current_url, :current_user, :return_to_url, :current_agent, :agent_logged_in?, :allow_page_to_be_cached?
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

  def render_500(exception=nil)
    if $ERROR_LOGGING && !$IGNORED_EXCEPTIONS.include?(exception.to_s)
       ErrorLog.create(
         :url=>request.url,
         :ip_address=>request.remote_ip,
         :user_agent=>request.user_agent,
         :user_id=>current_user.id,
         :exception_name=>exception.to_s,
         :backtrace=>"Application Server: " + $IP_ADDRESS_OF_SERVER + "\r\n" + exception.backtrace.to_s
         )
     end
    respond_to do |type|
     type.html { render :layout=>'main',:template => "content/error"}
     type.all  { render :nothing => true }
    end
  end
  ## end override of exception notifiable default methods

  # this method determines if the main taxa page is allowed to be cached or not
  def allow_page_to_be_cached?
    return !(agent_logged_in? or current_user.is_admin?)
  end

  # store a given URL (defaults to current) in case we need to redirect back later
  def store_location(url=url_for(:controller=>controller_name, :action=>action_name))
      session[:return_to]=url
  end

  # retrieve the stored URL that we want to go back to
  def return_to_url
    session[:return_to] || root_url
  end
  
  # Set the page expertise and vetted defaults, get from querystring, update the session with this value if found
  def set_user_settings
    expertise = params[:expertise] if ['novice','middle','expert'].include?(params[:expertise])
    alter_current_user do |user|
      user.expertise=expertise unless expertise.nil?
    end
    vetted = params[:vetted]
    alter_current_user do |user|
      user.vetted=EOLConvert.to_boolean(vetted) unless vetted.blank?
    end
  end
  
  def valid_return_to_url
    return_to_url != nil && return_to_url != login_url && return_to_url != register_url && return_to_url != logout_url && !url_for(:controller=>'content_partner',:action=>'login',:only_path=>true).include?(return_to_url)
  end

  def current_url(remove_querystring=true)
    if remove_querystring
      current_url=URI.parse(request.url).path
    else
      request.url
    end
  end

  def referred_url
    request.referer
  end

  # Redirect to the URL stored by the most recent store_location call or to the passed default.
  def redirect_back_or_default(default=root_url(:protocol => "http"))
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
    error_list=''
    model_object.errors.each{|attr,msg| error_list += "#{attr} #{msg}," }
    return error_list.chomp(',')
  end

  # called to log and redirect a user to an external link
  def external_link

    url=params[:url]
    if url.nil?
      render :nothing=>true
      return
    end

    ExternalLinkLog.log url, request, current_user if $ENABLE_DATA_LOGGING

    redirect_to url

  end

  # check to see if a session exists, and create if it not
  #  even non-logged in users get a session to store their expertise and language preferences
  def set_session
    unless logged_in?

       create_new_user
       clear_old_sessions if $USE_SQL_SESSION_MANAGEMENT
       session[:page_views]=0 if $SHOW_SURVEYS  # if we are showing surveys, we need to record how many page views this user has done

       # expire home page fragment caches after specified internal to keep it fresh
       if $CACHE_CLEARED_LAST.advance(:hours=>$CACHE_CLEAR_IN_HOURS) < Time.now
         expire_cache('home')
         $CACHE_CLEARED_LAST=Time.now()
       end

    end
  end

  # expire a single non-species page fragment cache
  def expire_cache(page_name)
    expire_pages(ContentPage.find_all_by_page_name(page_name))
  end

  # just clear all fragment caches quickly
  def clear_all_caches
    Rails.cache.clear
    
    #remove cached feeds
    FileUtils.rm_rf(Dir.glob("#{RAILS_ROOT}/public/feeds/*")) # TODO: wish there was a better way to do this
                                                              # using expire_page doesn't expire pages with id's
    #remove cached list of taxon_concepts                                             
    FileUtils.rm_rf("#{RAILS_ROOT}/public/content/tc_api/page")
    expire_page( :controller => 'content', :action => 'tc_api' )
    
    if ActionController::Base.cache_store.class == ActiveSupport::Cache::MemCacheStore
      ActionController::Base.cache_store.clear
      return true
    else
      return false
    end
  end

  # expire the header and footer caches
  def expire_menu_caches
    expire_pages(['top_nav', 'footer', 'exemplars'])
  end

  # expire the non-species page fragment caches
  def expire_caches
    expire_menu_caches
    expire_pages(ContentPage.find_all_by_active(true))
    $CACHE_CLEARED_LAST=Time.now()
  end

  # expire a list of taxa_ids specifed as an array
  # (add :expire_ancestors=>false if you don't want to expire that taxon_concept's ancestors as well)
  # TODO -- optimize, this will result in a lot of queries if you expire a lot of taxa
  def expire_taxa(taxa_ids, params={})

    return false if taxa_ids == nil? || taxa_ids.class != Array

    expire_ancestors=params[:expire_ancestors]
    expire_ancestors=true if params[:expire_ancestors].blank?

    taxa_ids_to_expire=[]

    if expire_ancestors # also expire ancestors
      # go over taxa_ids and find ancestors, and add them to the list
      taxa_ids.each do |taxon_concept_id|
        taxon_concept=TaxonConcept.find_by_id(taxon_concept_id)
        taxa_ids_to_expire += taxon_concept.ancestry.collect {|an| an.taxon_concept_id} unless taxon_concept.nil?
      end
      taxa_ids_to_expire.uniq! # eliminate duplicates
    else # don't expire ancestors, so just go through the supplied list and expire those
      taxa_ids_to_expire=taxa_ids
    end

    # now expire the list of taxa, ignoring ancestors (since they are now included in our global list)
    taxa_ids_to_expire.each do |taxon_concept_id|
      expire_taxon_concept(taxon_concept_id, :expire_ancestors=>false)
    end

    return true

  end

  def expire_data_object(data_object_id)
    expired_ids = Set.new
    DataObject.find(data_object_id).taxon_concepts.each do |tc|
      expire_taxon_concept(tc.id, :expire_ancestors => false) if expired_ids.add?(tc.id)
      begin
        tc.ancestors.each do |tca|
          expire_taxon_concept(tca.id, :expire_ancestors => false) if expired_ids.add?(tca.id)
        end
      rescue Exception => e
        if e.to_s != "Taxon concept must have at least one hierarchy entry"
          raise e
        end
      end
    end

  end

  # expire the fragment cache for a specific taxon_concept ID
  # (add :expire_ancestors=>false if you don't want to expire that s's ancestors as well)
  # TODO -- come up with a better way to expire taxa or name the cached parts -- this expiration process is very expensive due to all the iterations for each taxa id
  def expire_taxon_concept(taxon_concept_id,params={})

   #expire the given taxon_concept_id
   return false if taxon_concept_id == nil || taxon_concept_id.to_i == 0

   taxon_concept=TaxonConcept.find_by_id(taxon_concept_id)
   return false if taxon_concept.nil?

   expire_ancestors=params[:expire_ancestors]
   expire_ancestors=true if params[:expire_ancestors].nil?

   if expire_ancestors
     taxa_ids=taxon_concept.ancestry.collect {|an| an.taxon_concept_id}
   else
     taxa_ids=[taxon_concept_id]
   end

   expire_all_variants_of_taxa(taxa_ids)
    return true

  end

  # check if the requesting IP address is allowed (used to resrict methods to specific IPs, such as MBL/EOL IPs)
  def allowed_request
    !((request.remote_ip =~ /127.0.0.1/).nil? && (request.remote_ip =~ /128.128./).nil? && (request.remote_ip =~ /10.19./).nil?)
  end


  # send user back to the non-SSL version of the page
  def redirect_back_to_http
    redirect_to :protocol => "http://" if request.ssl?
  end

  # default new user when we don't have a logged in user
  def create_new_user
    session[:user_id] = nil
    User.create_new(:remote_ip=>request.remote_ip)
  end

  def reset_session
    create_new_user
    current_agent=nil
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
    yield(user)
    user.save! if logged_in?
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
    not session[:user_id].nil?
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
    flash[:warning]="We apologize, but the user registration system is not currently available.  Please try again later."[:user_system_down]
    redirect_to root_url
  end

  # A user is not authorized for the particular controller based on the rights for the roles they are in
  def access_denied
    flash.now[:warning]="You are not authorized to perform this action."[]
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
    return_to=(params[:return_to].blank? ? root_url : params[:return_to])
    redirect_to return_to
  end

  # ajax call to set the session variable for the user to indicate if flash is enabled or not
  def set_flash_enabled
    flash_enabled=params[:flash_enabled]
    alter_current_user do |user|
      if EOLConvert.to_boolean(flash_enabled)
        user.flash_enabled = true
      else
        user.flash_enabled = false
        user.default_taxonomic_browser="text"
      end
    end
    render :nothing=>true
  end

    # pulled over from Rails core helper file so it can be used in controllers as well
    def escape_javascript(javascript)
       (javascript || '').gsub('\\','\0\0').gsub('</','<\/').gsub(/\r\n|\n|\r/, "\\n").gsub(/["']/) { |m| "\\#{m}" }
    end

    # we are going to keep track of how many taxa pages the user has seen so we can determine if we are going to show the survey link or not
    # this defines our logic for if we show a survey or not on this page view
    def show_survey?

      # show survey on third taxa page view if not logged in and if not already asked before according to the cookie value
      if session[:page_views] == 3 && current_user.id.nil? && cookies[:survey_taken].nil?
        # if we are counting visitors, show survey every tenth visitor, if not, show it 10% of the time at random
        if  rand(0)<0.1
          return true
        else
          return false
        end
      end

    end

    def set_session_hierarchy_variable
      hierarchy_id = current_user.default_hierarchy_valid? ? current_user.default_hierarchy_id : Hierarchy.default.id
      secondary_hierarchy_id = current_user.secondary_hierarchy_id rescue nil
      @session_hierarchy = Hierarchy.find(hierarchy_id)
      @session_secondary_hierarchy = secondary_hierarchy_id.nil? ? nil : Hierarchy.find(secondary_hierarchy_id)
    end

private

  # Rails cache (memcached, probably) version of the user, by id: 
  def cached_user
    User # KNOWN BUG (in Rails): if you end up with "undefined class/module" errors in a fetch() call, you must call
         # that class beforehand.
    Rails.cache.fetch("users/#{session[:user_id]}") { User.find(session[:user_id]) }
  end

  # Having a *temporary* logged in user, as opposed to reading the user from the cache, lets us change some values
  # (such as language or vetting) within the scope of a request *without* storing it the database.  So, for example,
  # when a URL includes "&vetted=true" (or some-such), we can serve that request with *temporary* user values that
  # don't change the user's DB values.
  def temporary_logged_in_user
    @logged_in_user
  end

  def set_temporary_logged_in_user(user)
    @logged_in_user = user
  end

  # There are several things we need to do when we change the (temporary) values on a logged-in user:
  # 
  # NOTE: if you want to change a user's settings, you need to use alter_current_user
  def set_logged_in_user(user)
    set_temporary_logged_in_user(user)
    #TODO: Remove old session flushing code
    session[:user]    = nil # This was the "new user", before we updated the code -- this is here to ensure we flush all old sessions and can probably safely be removed now.
    session[:user_id] = user.id
    set_unlogged_in_user(nil)
    Rails.cache.delete("users/#{session[:user_id]}")
  end

  def unlogged_in_user
    session[:user]
  end

  def set_unlogged_in_user(user)
    session[:user] = user
  end

  def expire_all_variants_of_taxa(tc_ids)
    tc_ids.each do |taxon_concept_id|
      unless taxon_concept_id.blank?
        Language.find_active.each do |language|
          %w{novice middle expert}.each do |expertise|
            %w{true false}.each do |vetted|
              %w{text flash}.each do |default_taxonomic_browser|
                [nil.to_s, Hierarchy.browsable_by_label.map {|h| h.id.to_s }].flatten.each do |default_hierarchy_id|
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
    end
  end

  def expire_pages(pages)
    if pages.length > 0
      Language.find_active.each do |language|
        pages.each do |page|
          if page.class == ContentPage
            expire_fragment(:controller => '/content', :part => "#{page.id.to_s }_#{language.iso_639_1}")
            expire_fragment(:controller => '/content', :part => "#{page.page_url}_#{language.iso_639_1}")
          else
            expire_fragment(:controller => '/content', :part => "#{page}_#{language.iso_639_1}")
          end
          if page.class == ContentPage && page.page_url == 'home'
            Hierarchy.all.each do |h|
              expire_fragment(:controller => '/content', :part=>"home_#{language.iso_639_1}_#{h.id.to_s}") # this is because the home page fragment is dependent on the user's selected hierarchy entry ID, unlike the other content pages
            end
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

  # we are going to keep track of how many pages the user has seen so we can determine if we are going to show the survey link or not
  def count_page_views
    session[:page_views]=0 if session[:page_views].nil?
    session[:page_views]+=1
  end

  def check_for_survey
    # check if it's time to show the survey
    @display_survey = show_survey? if $SHOW_SURVEYS
  end

  def log_data_objects_for_taxon_concept taxon_concept, *objects
    DataObjectLog.log objects, request, current_user, taxon_concept if $ENABLE_DATA_LOGGING && EOL.allowed_user_agent?(request.user_agent)
  end

  def log_search params
    Search.log(params, request, current_user) if $ENABLE_DATA_LOGGING && EOL.allowed_user_agent?(request.user_agent)
  end

  def update_logged_search params
    Search.update_log(params) if $ENABLE_DATA_LOGGING
  end

end
