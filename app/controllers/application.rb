require 'uri'

# make the sanitize_sql protected method in ActiveRecord base available as a public method called "eol_escape_sql"
module ActiveRecord
    class Base
        def self.eol_escape_sql(sql)
            sanitize_sql(sql)
        end
   end
end

class ApplicationController < ActionController::Base

 if $EXCEPTION_NOTIFY || $ERROR_LOGGING
    include ExceptionNotifiable
    #local_addresses.clear   # uncomment this line if you want to test exception notification and db error logging even on localhost calls, you'll probably also need to set config.action_controller.consider_all_requests_local = false in your environment file
  end

  # if recaptcha is not enabled, then override the method to always return true
  unless $ENABLE_RECAPTCHA
    def verify_recaptcha
      true
    end
  end

  include ContentPartnerAuthenticationModule

  prepend_before_filter :set_session
  before_filter :clear_any_logged_in_session unless $ALLOW_USER_LOGINS

  helper :all

  helper_method :format_date,:format_date_time,:logged_in?, :current_user, :get_image_url, :get_first_agent, :return_to_url, :current_url
  helper_method :is_user_in_role?, :is_user_admin?, :convert_to_nbsp,:remove_html,:get_video_url, :get_agent_icons, :hh
  helper_method :current_agent, :agent_logged_in?, :truncate, :allow_page_to_be_cached?
  around_filter :set_current_language

## similar to h, but does not escape html code which is helpful for showing italisized names
def hh(input)
  result = input.dup.strip

  result.gsub!(/["]|&(?![\w]+;)/) do | match |
    case match
      when '&' then '&amp;'
      when '"' then '&quot;'
      else          ''
    end
  end
  result
end

  ## override exception notifiable default methods to redirect to our special error pages instead of the usual 404 and 500 and to do error logging
    def render_404
      respond_to do |type|
        flash.now[:warning]="The page you have requested does not exist."
        type.html { render :layout=>'main',:template => "content/error", :status => "404 Not Found" }
        type.all  { render :nothing => true, :status => "404 Not Found" }
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
       type.html { render :layout=>'main',:template => "content/error",:status => "500 Error" }
       type.all  { render :nothing => true, :status => "500 Error" }
      end
    end
    ## end override of exception notifiable default methods

    def format_date_time(inTime,params={})
         format_string=params[:format] || "long"
         format_string = case format_string
          when "short"
            "%m/%d/%Y - %I:%M %p %Z"
          when "short_no_tz"
            "%m/%d/%Y - %I:%M %p"
          when "long"
            "%A, %B %d, %Y - %I:%M %p %Z"
          else
            nil
         end
         inTime.strftime(format_string) unless inTime==nil
    end

    # Return a formatted date
    # Default format: %m/%d/%Y
    def format_date(date, format = "%m/%d/%Y")
      date.respond_to?(:strftime) ? date.strftime(format) : date.to_s
    end

  # this method determines if the main taxa page is allowed to be cached or not
  def allow_page_to_be_cached?
    !(agent_logged_in? || current_user.is_admin?) # if a content partner or admin is logged in, we do *not* want the page to be cached
  end

  # given a hash containing an agent node, returns a list of hyperlinked <img> tag icons
  # if :linked=>false, only the agent icons are returned even if links are available
  # if :normal_icon=>true the then normal sized icon is returned, otherwise the small version is returned
  def get_agent_icons(data,params={})

     linked=params[:linked]
     linked = true if linked.nil?
     normal_icon=params[:normal_icon]
     normal_icon = false if normal_icon.nil?

     if data.nil? == false && data['agent'].nil? == false
        data=EOLConvert.convert_to_hashed_array(data['agent'])
        agent_list=""
        data.each do |agent|
          if normal_icon
              icon=agent['icon'] || ""
          else
              icon=agent['smallIcon'] || ""
          end
          url=agent['agentHomepage'] || ""
          if linked && url != '' && icon != ''
            agent_list+="<a href=\"" + url + "\" target=\"_blank\">"
          end
          agent_list+="<img border=\"0\" src=\"/images/collection_icons/" + icon + "\">" if icon != ''
          if linked && url != '' && icon != ''
            agent_list+="</a>"
          end
          agent_list+="&nbsp;" if icon != ''
        end
        return agent_list.strip.chop
     else
        return ''
     end

  end

  # remove HTML from the given string
  def remove_html(input_string)
    return input_string.gsub(/(<[^>]*>)|\n|\t/s) {""}.strip
  end

  # store a given URL (defaults to current) in case we need to redirect back later
  def store_location(url=current_url)
      session[:return_to]=url
  end

  # retrieve the stored URL that we want to go back to
  def return_to_url
    session[:return_to] || root_url
  end

  # get the full current url being shown
  def current_url
    url_for(:controller=>controller_name, :action=>action_name)
  end

  def referred_url
    request.referer
  end

  # Redirect to the URL stored by the most recent store_location call or to the passed default.
  def redirect_back_or_default(default=root_url)

    # be sure we aren't returning the login, register or logout page
    if return_to_url != nil && return_to_url != login_url && return_to_url != register_url && return_to_url != logout_url && !url_for(:controller=>'content_partner',:action=>'login',:only_path=>true).include?(return_to_url)
      redirect_to(CGI.unescape(return_to_url),:protocol => "http://")
    else
      redirect_to(default,:protocol => "http://")
    end
    store_location(nil)
    return false

  end

  # get the local or remote image URL based on our preference setting
  def get_image_url(image_item)
      if ($PREFER_REMOTE_IMAGES && image_item['remoteURL'].nil? == false) or (image_item['localURL'].nil?)
        return image_item['remoteURL']
      else
        return image_item['localURL']
      end
  end

  # get the local or remote image URL based on the type of video
  def get_video_url(video_item)
    return case video_item['videoType'].downcase
      when "youtube" then video_item['remoteURL']
      when "flash"   then video_item['localURL']
      else                ''
    end
  end

  def collected_errors(model_object)
    error_list=''
    model_object.errors.each{|attr,msg| error_list += "#{attr} #{msg}," }
    return error_list.chomp(',')
  end

  # truncate a string to the maxlength passed and then add "..." if truncated
  def truncate(text, length = 30, truncate_string = "...")
    return if text.nil?
    l = length - truncate_string.chars.length
    text.chars.length > length ? text[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : text
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

    # if we don't have a session yet, create it, set taxa views to 0 for this user, and increment number of unique visitors
    if current_user.nil?

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
  # (add :expire_ancestors=>false if you don't want to expire that taxon's ancestors as well)
  # TODO -- optimize, this will result in a lot of queries if you expire a lot of taxa
  def expire_taxa(taxa_ids,params={})

    return false if taxa_ids == nil? || taxa_ids.class != Array

    expire_ancestors=params[:expire_ancestors]
    expire_ancestors=true if params[:expire_ancestors].blank?

    taxa_ids_to_expire=[]

    if expire_ancestors # also expire ancestors
      # go over taxa_ids and find ancestors, and add them to the list
      taxa_ids.each do |taxon_id|
        taxon=TaxonConcept.find_by_id(taxon_id)
        taxa_ids_to_expire += taxon.ancestry.collect {|an| an.taxon_concept_id} unless taxon.nil?
      end
      taxa_ids_to_expire.uniq! # eliminate duplicates
    else # don't expire ancestors, so just go through the supplied list and expire those
      taxa_ids_to_expire=taxa_ids
    end

    # now expire the list of taxa, ignoring ancestors (since they are now included in our global list)
    taxa_ids_to_expire.each do |taxon_id|
      expire_taxon_concept(taxon_id,:expire_ancestors=>false)
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

  # expire the fragment cache for a specific taxon ID
  # (add :expire_ancestors=>false if you don't want to expire that taxon's ancestors as well)
  # TODO -- come up with a better way to expire taxa or name the cached parts -- this expiration process is very expensive due to all the iterations for each taxa id
  def expire_taxon_concept(taxon_concept_id,params={})

   #expire the given taxon_id
   return false if taxon_concept_id == nil || taxon_concept_id.to_i == 0

   taxon=TaxonConcept.find_by_id(taxon_concept_id)
   return false if taxon.nil?

   expire_ancestors=params[:expire_ancestors]
   expire_ancestors=true if params[:expire_ancestors].nil?

   if expire_ancestors
     taxa_ids=taxon.ancestry.collect {|an| an.taxon_concept_id}
   else
     taxa_ids=[taxon_concept_id]
   end

   # expire given taxa for all active languages and possibilites
   taxa_ids.each do |taxon_id|
     unless taxon_id.blank?
       Language.find_active.each do |language|
          %w{novice middle expert}.each do |expertise|
            %w{true false}.each do |vetted|
              %w{text flash}.each do |default_taxonomic_browser|
                %w{true false}.each do |can_curate|
                  part_name='page_' + taxon_id.to_s + '_' + language.iso_639_1 + '_' + expertise + '_' + vetted + '_' + default_taxonomic_browser + '_' + can_curate
                  expire_fragment(:controller=>'/taxa',:part=>part_name)
                end
              end
            end
          end
        end
      end
    end
    return true

  end

  # check if the requesting IP address is allowed (used to resrict methods to specific IPs, such as MBL/EOL IPs)
  def allowed_request
    !((request.remote_ip =~ /127.0.0.1/).nil? && (request.remote_ip =~ /128.128./).nil? && (request.remote_ip =~ /10.19./).nil?)
  end

  # send user to the SSL version of the page (used in the account controller, can be used elsewhere)
  def redirect_to_ssl
     redirect_to :protocol => "https://" unless (request.ssl? or local_request?)
  end

  # send user back to the non-SSL version of the page
  def redirect_back_to_http
    redirect_to :protocol => "http://" if request.ssl?
  end

  # default new user when we don't have a logged in user
  def create_new_user
     new_user=User.create_new(:remote_ip=>request.remote_ip)
     session[:user]=new_user
  end

  def reset_session
      create_new_user
      current_agent=nil
  end

  # return currently logged in user
  def current_user
    session[:user]
  end

   # set current user in session
  def set_current_user(user)
    session[:user]=user
  end

  # this method is used as a before_filter when user logins are disabled to ensure users who may have had a previous session
  # before we switched off user logins is booted out
  def clear_any_logged_in_session
    reset_session if logged_in?
  end

  ###########
  # AUTHENTICATION/AUTHORIZATION METHODS

  # check to see if we have a logged in user
  def logged_in?
    !current_user.id.nil?
  end

 def check_authentication
     must_log_in unless logged_in?
     return false
 end

  # check membership in a specific role
  def is_user_in_role?(role)
    return current_user.roles.include?(Role.find_by_title(role))
  end

  def is_user_admin?
    return is_user_in_role?("Administrator")
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
   flash[:notice] = "You don't have privileges to access this action"
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
      flash.now[:warning]='You are not authorized to perform this action.'
      request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to root_url)
    end
#
#############

  # Set the current language
  def set_language
    language = params[:language].to_s
    languages = Gibberish.languages.map { |l| l.to_s } + ["en"]
    current_user.language = Language.find_by_iso_639_1(language) if languages.include?(language)
    return_to=(params[:return_to].blank? ? root_url : params[:return_to])
    redirect_to return_to
  end

  # ajax call to set the session variable for the user to indicate if flash is enabled or not
  def set_flash_enabled
    flash_enabled=params[:flash_enabled]
    if EOLConvert.to_boolean(flash_enabled)
      current_user.flash_enabled = true
    else
      current_user.flash_enabled = false
      current_user.default_taxonomic_browser="text"
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

    def convert_to_nbsp(input_string)
      if input_string.nil? == false
        return input_string.gsub('&', '&amp;').gsub(' ','&nbsp;')
      else
        return ''
      end
    end

private

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
