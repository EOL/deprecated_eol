require 'uri'
require 'ezcrypto'
require 'cgi'
require 'base64'

class AccountController < ApplicationController

  before_filter :check_authentication, :only => [:profile, :uservoice_login]
  before_filter :go_to_home_page_if_logged_in, :except => [:uservoice_login, :check_username, :check_email, :profile, :show, :logout, :new_openid_user, :reset_password, :save_reset_password, :show_objects_curated, :show_species_curated, :show_comments_moderated]
  before_filter :accounts_not_available unless $ALLOW_USER_LOGINS  
  if $USE_SSL_FOR_LOGIN 
    before_filter :redirect_to_ssl, :only=>[:login, :authenticate, :signup, :profile, :reset_password] 
  end

  if $SHOW_SURVEYS
    before_filter :check_for_survey
    after_filter :count_page_views
  end
  layout 'main'

  def login    

    # It's possible to create a redirection attack with a redirect to data: protocol... and possibly others, so:
    params[:return_to] = nil unless params[:return_to] =~ /\A[%2F\/]/ # Whitelisting redirection to our own site, relative paths.

    # TEMPORARY
    params[:return_to] = nil if params[:return_to] == 'boom'

    # Makes no sense to bounce them back to the login page in the rare case they clicked "login" twice:
    params[:return_to] = nil if params[:return_to] =~ /login/

    store_location(params[:return_to]) unless params[:return_to].blank? # store the page we came from so we can return there if it's passed in the URL

  end

  def authenticate

    # reset the agent session in case there are any content partners logged in to avoid any funny things
    session[:agent_id] = nil

    user_params=params[:user]
    remember_me=EOLConvert.to_boolean(params[:remember_me])
        
    if using_open_id?
      open_id_authentication(params[:openid_url],remember_me)
    else
      password_authentication(user_params[:username],user_params[:password],remember_me)
    end

  end

  def signup
    unless request.post?
      current_user.id=nil 
      store_location(params[:return_to]) unless params[:return_to].nil? # store the page we came from so we can return there if it's passed in the URL
      return
    end

    set_curator_clade(params)

    # create a new user with the defaults and then update with the user entered values on the signup form
    @user = User.create_new(params[:user])

    # no initial roles for a new web user
    @user.roles = []

    # give them a validation code and make their account not active by default
    @user.validation_code = User.hash_password(@user.username)
    @user.active = false

    # set the password and the remote_IP address
    @user.password = @user.entered_password
    @user.remote_ip = request.remote_ip
    if verify_recaptcha &&  @user.save
      @user.update_attribute :agent_id, Agent.create_agent_from_user(:full_name => @user.full_name).id
      @user.entered_password = ''
      @user.entered_password_confirmation = ''
      Notifier.deliver_registration_confirmation(@user)
      redirect_to :action => 'confirmation_sent',:protocol => "http://"
      return
    else # verify recaptcha failed or other validation errors
      @verification_did_not_match = "The verification phrase you entered did not match."[:verification_phrase_did_not_match] unless verify_recaptcha
    end

  end

  def confirmation_sent

  end

  # users come here from the activation email they receive
  def confirm

      params[:id] ||= ''
      params[:validation_code] ||= ''
      @user=User.find_by_username_and_validation_code(params[:id],params[:validation_code])

      if !@user.blank?
        @user.update_attributes(:active=>true) # activate their account
        Notifier.deliver_welcome_registration(@user) # send them a welcome message
      end

  end

  def logout
    params[:return_to] = nil unless params[:return_to] =~ /\A[%2F\/]/ # Whitelisting redirection to our own site, relative paths.
    cookies.delete :user_auth_token       
    reset_session 
    store_location(params[:return_to])
    flash[:notice] = "You have been logged out."[:you_have_been_logged_out]
    redirect_back_or_default
  end

  def forgot_password
    if request.post?
      user           = params[:user]
      username_string       = user[:username].strip == '' ? nil : user[:username].strip
      email_string          = user[:email].strip == '' ? nil : user[:email].strip
      user_with_forgotten_pass = User.find_by_username(username_string) || User.find_by_email(email_string) 
      if user_with_forgotten_pass
        Notifier.deliver_forgot_password_email(user_with_forgotten_pass, request.port)
        flash[:notice] = "Check your email to reset your password"[:reset_password_instructions_emailed] #TODO remove old add new translation
        redirect_to root_url(:protocol => "http")  # need protocol for flash to survive
      else
        flash.now[:notice] = "No matching accounts found"[:cannot_find_user_or_email] #TODO remove old add new translation
      end
    end
  end

  def save_reset_password
    password = params[:user][:entered_password]
    password_confirmation = params[:user][:entered_password_confirmation]
    user = User.find(params[:user][:id])
    user.update_attributes(:active => true, :entered_password => password, :password => password, :entered_password_confirmation => password_confirmation)
    flash[:notice] = "Your password is updated"[:user_password_updated_successfully]
    redirect_to root_url(:protocol => "http")
  end

  def reset_password
    password_reset_token = params[:id]
    user = User.find_by_password_reset_token(password_reset_token)
    if user
      is_expired = Time.now > user.password_reset_token_expires_at
      if is_expired
        go_to_forgot_password(user)
      else
        set_current_user(user)
        delete_password_reset_token(user)
        render
      end
    else
      go_to_forgot_password(user)
    end
  end

  def profile

    # grab logged in user
    @user = current_user
    old_user=@user.clone
    
    unless request.post? # first time on page, get current settings
      # set expertise to a string so it will be picked up in web page controls
      @user.expertise=current_user.expertise.to_s
      store_location(params[:return_to]) unless params[:return_to].nil? # store the page we came from so we can return there if it's passed in the URL
      return
    end

    user_params=params[:user]
    
    # change password if user entered it
    # TODO This is pretty ugly, but validation on passwords is really only valid on create OR on update if users actually enter a password
    unless user_params[:entered_password].blank? && user_params[:entered_password_confirmation].blank?
       if user_params[:entered_password].length < 4 || user_params[:entered_password].length > 16
          @user.errors.add_to_base("Password length must be between 4 and 16 characters."[:password_must_be_4to16_characters])
          return
      end
      @user.password=user_params[:entered_password]
    end
    
    # The UI would not allow this, but a hacker might try to grant curator permissions to themselves in this manner.
    user_params.delete(:curator_approved) unless is_user_admin? 

    set_curator_clade(params)

    if @user.update_attributes(user_params)
      user_changed_mailing_list_settings(old_user,@user) if (old_user.mailing_list != @user.mailing_list) || (old_user.email != @user.email)
      set_current_user(@user)
      flash[:notice] = "Your preferences have been updated."[:your_preferences_have_been_updated]
      redirect_back_or_default
    end

  end

  # AJAX call to check if name is unique from signup page
  def check_username

    username=params[:username] || ""
    if User.unique_user?(username) || (logged_in? && current_user.username == username)
      message=""
    else
      message="{name} is already taken"[:username_taken,username]
    end

    render :update do |page|
      page.replace_html 'username_warn', message
    end

  end

  # AJAX call to check if email is unique from signup page
  def check_email

    email=params[:email] || ""
    if User.unique_email?(email) || (logged_in? && current_user.email == email)
      message=""
    else
      message="{email} is already taken"[:username_taken,email]
    end

    render :update do |page|
      page.replace_html 'email_warn', message
    end

  end
  
  def show
    @user = User.find(params[:id])
    redirect_back_or_default unless @user.curator_approved
  end
  
  def show_objects_curated    
    @user = User.find(params[:id])    
    @data_object_ids = @user.data_object_ids_curated    
    @object_ids_activity = @user.data_object_ids_curated_with_activity(@user.id)    
    page = params[:page] || 1    
    @posts = DataObject.data_object_details(@data_object_ids, page)
  end
  
  def show_species_curated    
    @user = User.find(params[:id])    
    @taxon_concept_ids = @user.taxon_concept_ids_curated
    page = params[:page] || 1
    @posts = TaxonConcept.from_taxon_concepts(@taxon_concept_ids, page)
  end
  
  def show_comments_moderated    
    @user = User.find(params[:id])    
    @comment_ids = @user.comment_ids_curated(@user.id)
    @comment_ids_activity = @user.comment_ids_moderated_with_activity(@user.id)
    page = params[:page] || 1
    @posts = Comment.get_comments(@comment_ids, page)
  end
  

  # this is the uservoice single sign on redirect
  def uservoice_login
    
    user=Hash.new
    user[:guid]="eol_#{current_user.id}"
    user[:expires]=Time.now + 5.hours
    user[:email]=current_user.email
    user[:display_name]=current_user.full_name
    user[:locale]=current_user.language.iso_639_1
    current_user.is_admin? ? user[:admin]='accept' : user[:admin]='deny'
    json_token=user.to_json
              
    key = EzCrypto::Key.with_password $USERVOICE_ACCOUNT_KEY, $USERVOICE_API_KEY
    encrypted = key.encrypt(json_token)
    token = CGI.escape(Base64.encode64(encrypted)).gsub(/\n/, '')
        
    redirect_to "#{$USERVOICE_URL}?sso=#{token}"
    
  end
  
  private

  def delete_password_reset_token(user)
    user.update_attributes(:password_reset_token => nil, :password_reset_token_expires_at => nil) if user
  end

  def go_to_forgot_password(user)
    flash[:notice] = "Expired link, you can generate it again"[:expired_reset_password_link]
    delete_password_reset_token(user)
    redirect_to :action => "forgot_password", :protocol => "http"
  end

  def password_authentication(username, password, remember_me)
    user = User.authenticate(username,password)
    if user[0]
      successful_login(user[1],remember_me)
    else
      failed_login(user[1])
    end
  end

  def open_id_authentication(identity_url,remember_me)
    open_id_return_to = "#{realm}/account/authenticate?remember_me=#{remember_me}"
    authenticate_with_open_id(identity_url,
                              :return_to => open_id_return_to,
                              :optional => [ :fullname, :nickname, :email ]) do |result, identity_url, registration|
      if result.successful? # open ID verification succeeded
        user = User.find_by_identity_url_and_active(identity_url,true) # see if user has logged into EOL before
        new_openid_user=false
        if user.nil? # if not, create them a row in our database
          new_openid_user   = true
          user              = User.create_new()
          temp_username     = "#{identity_url[0..31]}"
          user.identity_url = identity_url
          user.username     = temp_username
          user.email        = registration['email'] || ''
          user.given_name   = temp_username 
          user.remote_ip    = request.remote_ip
          user.save!
          new_username      = "openid_user_#{user.id.to_s}"
          new_given_name    = (registration['nickname'].blank? ? new_username : registration['nickname']) 
          user.update_attributes(:username=>new_username,:given_name=>new_given_name)
          new_openid_user=true
        end
        successful_login(user, remember_me, new_openid_user)
      else
        failed_login result.message
      end
    end
  end

  def successful_login(user, remember_me, new_openid_user = false)
    set_current_user(user)
    notice_message="Logged in successfully."[:logged_in]   
    if remember_me && !user.is_admin?
      user.remember_me
      cookies[:user_auth_token] = { :value => user.remember_token , :expires => user.remember_token_expires_at }
    elsif remember_me && user.is_admin?
      notice_message+=" NOTE: for security reasons, administrators cannot use the remember me feature."[:admin_remind_me_message]
    end    
    flash[:notice] = notice_message
    # could catch the fact that they are a new openid user here and redirect somewhere else if you wanted
    if user.is_admin? && ( session[:return_to].nil? || session[:return_to].empty?) # if we're an admin we STILL would love a return, thank you very much!
      redirect_to :controller => 'admin', :action => 'index', :protocol => "http://"
    else
      redirect_back_or_default
    end
  end

  def failed_login(message)
    # TODO - send an email to an admin if user.failed_logins > 10 # Smells like a dictionary attack!
    flash[:warning] = message
    redirect_to :action => 'login'
  end  

  def set_curator_clade(params)
    # Remove hierachy association if they selected one but then changed their minds.
    if params['selected-clade-id'.to_sym] != nil && params['selected-clade-id'.to_sym] != ''
      params[:user][:curator_hierarchy_entry_id] = params['selected-clade-id'.to_sym]
    end
    # Remove the pseudo-column before creating the real record.
    params[:user].delete :curator
  end
  
  # this method is called if a user changes their mailing list or email address settings
  # TODO: do something more intelligent here to notify mailing service that a user changed their settings (like call a web service, or log in DB to create a report)
  def user_changed_mailing_list_settings(old_user,new_user)
    media_inquiry_subject=ContactSubject.find_by_id($MEDIA_INQUIRY_CONTACT_SUBJECT_ID)
    if media_inquiry_subject.nil? 
      recipient="test@eol.org"
    else
      recipient=media_inquiry_subject.recipients
    end    
    Notifier.deliver_user_changed_mailer_setting(old_user,new_user,recipient)
  end
  
  # In order for AccountController to work with OpenID, we need to force it to use https when authenticating.  
  def realm
    return $PRODUCTION_MODE ? "https://#{request.host_with_port}" : "#{request.protocol + request.host_with_port}"
  end

end
