require 'uri'
require 'ezcrypto'
require 'cgi'
require 'base64'

class AccountController < ApplicationController

  before_filter :check_authentication, :only => [:info, :profile, :uservoice_login]
  before_filter :go_to_home_page_if_logged_in, :except => [:uservoice_login, :check_username, :check_email, :info, :profile,
    :show, :logout, :reset_password, :reset_specific_users_password,
    :show_objects_curated, :show_species_curated, :show_comments_moderated]
  before_filter :accounts_not_available unless $ALLOW_USER_LOGINS  
  if $USE_SSL_FOR_LOGIN 
    before_filter :redirect_to_ssl, :only=>[:login, :authenticate, :signup, :info, :profile, :reset_password] 
  end
  
  layout 'main'

  @@objects_per_page = 20

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

    user_params = params[:user]
    remember_me = EOLConvert.to_boolean(params[:remember_me])

    password_authentication(user_params[:username],user_params[:password],remember_me)

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
      @user.update_attribute :agent_id, Agent.create_agent_from_user(@user.full_name).id
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
      user   = params[:user]
      @name  = user[:username].strip == '' ? nil : user[:username].strip
      @email = user[:email].strip == '' ? nil : user[:email].strip
      @users = User.find_all_by_username(@name) 
      @users = User.find_all_by_email(@email) if @users.empty?
      if @users.size == 1
        @users.each do |user_with_forgotten_pass|
          Notifier.deliver_forgot_password_email(user_with_forgotten_pass, request.port)
        end
        flash[:notice] = "Check your email to reset your password"[:reset_password_instructions_emailed]
        redirect_to root_url(:protocol => "http")  # need protocol for flash to survive
      elsif @users.size > 1
        render :action => 'multiple_users_with_forgotten_password'
        return
      else
        flash.now[:notice] = "No matching accounts found"[:cannot_find_user_or_email]
      end
    end
  end

  def reset_specific_users_password
    user = User.find(params[:id])
    if user
      Notifier.deliver_forgot_password_email(user, request.port)
      @success = true
    else
      @success = false
    end
    render :partial => 'reset_specific_users_password_response'
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
      go_to_forgot_password(nil)
    end
  end

  def info
    @user = User.find(current_user.id)
    @user_info = @user.user_info
    @user_info ||= UserInfo.new
    unless request.post? # first time on page, get current settings
      store_location(params[:return_to]) unless params[:return_to].nil?
      return
    end
    it_worked = false
    if @user.user_info
      it_worked = @user.user_info.update_attributes(params[:user_info])
    else
      it_worked = @user.user_info = UserInfo.create(params[:user_info])
    end 
    if it_worked
      flash[:notice] = "Your information has been updated. Thank you for contributing to EOL."[]
      redirect_back_or_default
    end
  end

  def profile

    # grab logged in user
    @user = User.find(current_user.id)
    old_user=@user.clone

    unless request.post? # first time on page, get current settings
      # set expertise to a string so it will be picked up in web page controls
      @user.expertise=current_user.expertise.to_s
      store_location(params[:return_to]) unless params[:return_to].nil? # store the page we came from so we can return there if it's passed in the URL
      return
    end

    user_params=params[:user]
    unset_auto_managed_password 
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
  # Note the around_filter MasterFilter causes this to READ from master.  Very important!
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
    @user_submitted_text_count = UsersDataObject.count(:conditions=>['user_id = ?',params[:id]])
    redirect_back_or_default unless @user.curator_approved
  end

  def show_objects_curated
    page = (params[:page] || 1).to_i
    @user = User.find(params[:id])
    @data_objects_curated = @user.data_objects_curated
    @data_objects = @data_objects_curated.paginate(:page => page, :per_page => @@objects_per_page)
  end

  def show_species_curated
    page = (params[:page] || 1).to_i
    @user = User.find(params[:id])
    @taxon_concept_ids = @user.taxon_concept_ids_curated.paginate(:page => page, :per_page => @@objects_per_page)
  end

  def show_comments_moderated
    page = (params[:page] || 1).to_i
    @user = User.find(params[:id])
    @all_comments = @user.comments_curated
    @comments = @all_comments.paginate(:page => page, :per_page => @@objects_per_page)
  end


  # this is the uservoice single sign on redirect
  def uservoice_login
    token = current_user.uservoice_token
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

  def successful_login(user, remember_me)
    set_current_user(user)
    notice_message="Logged in successfully."[:logged_in]   
    if remember_me && !user.is_admin?
      user.remember_me
      cookies[:user_auth_token] = { :value => user.remember_token , :expires => user.remember_token_expires_at }
    elsif remember_me && user.is_admin?
      notice_message+=" NOTE: for security reasons, administrators cannot use the remember me feature."[:admin_remind_me_message]
    end    
    flash[:notice] = notice_message
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

  def realm
    return $PRODUCTION_MODE ? "https://#{request.host_with_port}" : "#{request.protocol + request.host_with_port}"
  end

  #Change password parameters when they are set automatically by an autofil password management of a browser (known behavior of Firefox for example)  
  def unset_auto_managed_password
    password = params[:user][:entered_password].strip
    if params[:user][:entered_password_confirmation].blank? && !password.blank? && User.hash_password(password) == User.find(current_user.id).hashed_password
      params[:user][:entered_password] = ''
    end
  end

end
