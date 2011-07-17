class AccountController < ApplicationController

  layout 'v2/application'

  before_filter :check_authentication, :except => [ :login, :register, :authenticate, :logout, :signup, :check_username,
    :check_email, :confirmation_sent, :confirm, :forgot_password, :reset_specific_users_password, :reset_password ]
  before_filter :go_to_home_page_if_logged_in, :only => [ :login, :register, :signup, :authenticate]

  # def login
  #     # Makes no sense to bounce them back to the login page in the rare case they clicked "login" twice:
  #     params[:return_to] = nil if params[:return_to] =~ /login/
  #     store_location(params[:return_to]) unless params[:return_to].blank? # store the page we came from so we can return there if it's passed in the URL
  #   end

  # def authenticate
  #   # reset the agent session in case there are any content partners logged in to avoid any funny things
  #   user_params = params[:user]
  #   remember_me = EOLConvert.to_boolean(params[:remember_me])
  #   password_authentication(user_params[:username],user_params[:password],remember_me)
  # end

#  def signup
#    unless request.post? && params[:user]
#      current_user.id = nil
#      store_location(params[:return_to]) unless params[:return_to].nil? # store the page we came from so we can return there if it's passed in the URL
#      return
#    end
#
#    # create a new user with the defaults and then update with the user entered values on the signup form
#    @user = User.create_new(params[:user])
#
#    # give them a validation code and make their account not active by default
#    @user.validation_code = Digest::MD5.hexdigest "#{@user.username}#{Time.now.hour}:#{Time.now.min}:#{Time.now.sec}"
#    while(User.find_by_validation_code(@user.validation_code))
#      @user.validation_code.succ!
#    end
#    @user.active = false
#
#    # set the password and the remote_IP address
#    @user.password = @user.entered_password
#    @user.remote_ip = request.remote_ip
#    if verify_recaptcha && @user.save
#      begin
#        @user.update_attribute :agent_id, Agent.create_agent_from_user(@user.full_name).id
#      rescue ActiveRecord::StatementInvalid
#        # Interestingly, we are getting users who already have agents attached to them.  I'm not sure why, but it's causing registration to fail (or seem to; the user is created), and this is bad.
#      end
#      @user.entered_password = ''
#      @user.entered_password_confirmation = ''
#      Notifier.deliver_registration_confirmation(@user)
#      redirect_to :action => 'confirmation_sent', :protocol => "http://"
#      return
#    else # verify recaptcha failed or other validation errors
#      @verification_did_not_match =  I18n.t(:verification_phrase_did_not_match)  unless verify_recaptcha
#    end
#  end
#
#  def confirmation_sent
#  end

  # users come here from the activation email they receive
  # def confirm
  #     params[:id] ||= ''
  #     params[:validation_code] ||= ''
  #     params[:return_to] = nil
  #     User.with_master do
  #       @user = User.find_by_username_and_validation_code(params[:id], params[:validation_code])
  #     end
  #     if !@user.blank?
  #       @user.activate
  #     end
  #   end

  # def logout
  #     # Whitelisting redirection to our own site, relative paths.
  #     params[:return_to] = nil unless params[:return_to] =~ /\A[%2F\/]/
  #     cookies.delete :user_auth_token
  #     reset_session
  #     store_location(params[:return_to])
  #     flash[:notice] =  I18n.t(:you_have_been_logged_out)
  #     redirect_back_or_default
  #   end


  def forgot_password
    if params[:user] && request.post?
      user = params[:user]
      @name = user[:username].strip == '' ? nil : user[:username].strip
      @email = user[:email].strip == '' ? nil : user[:email].strip
      @users = User.find_all_by_username(@name)
      @users = User.find_all_by_email(@email) if @users.empty?
      store_location(params[:return_to]) unless params[:return_to].nil? # store the page we came from so we can return there if it's passed in the URL

      if @users.size == 1
        @users.each do |user_with_forgotten_pass|
          Notifier.deliver_forgot_password_email(user_with_forgotten_pass, request.port)
        end
        flash[:notice] =  I18n.t(:reset_password_instructions_emailed)
        redirect_to root_url(:protocol => "http")  # need protocol for flash to survive
      elsif @users.size > 1
        render :action => 'multiple_users_with_forgotten_password'
        return
      else
        flash.now[:notice] =  I18n.t(:cannot_find_user_or_email)
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
        redirect_to :action => "profile"
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
      current_user.log_activity(:updating_info)
      return
    end
    it_worked = false
    if @user.user_info
      it_worked = @user.user_info.update_attributes(params[:user_info])
    else
      it_worked = @user.user_info = UserInfo.create(params[:user_info])
    end
    if it_worked
      current_user.log_activity(:updated_info)
      flash[:notice] = I18n.t(:your_information_has_been_updated_thank_you_for_contributing_to_eol)
      redirect_back_or_default
    end
  end

  def profile
    @page_header = I18n.t("account_settings")
    @user = User.find(current_user.id)
    if params[:user] && request.post?
      unset_auto_managed_password
      if params[:user][:entered_password] && params[:user][:entered_password_confirmation]
        if !password_length_okay?
          flash[:error] = I18n.t(:password_must_be_4to16_characters)
          return
        elsif params[:user][:entered_password] != params[:user][:entered_password_confirmation]
          flash[:error] = I18n.t(:passwords_must_match)
          return
        end
        alter_current_user do |user|
          user.password = params[:user][:entered_password]
        end
      end
      current_user.log_activity(:updated_profile)
      alter_current_user do |user|
        user.update_attributes(params[:user])
      end
      flash[:notice] =  I18n.t(:your_preferences_have_been_updated)
      redirect_back_or_default
    end
    @user = User.find(current_user.id)
  end

  def personal_profile
    @page_header = I18n.t("personal_profile_menu")
    if params[:user] && request.post?
      current_user.log_activity(:updated_profile)
      alter_current_user do |user|
        user.update_attributes(params[:user])
        upload_logo(user) unless params[:user][:logo].blank?
      end
      flash[:notice] =  I18n.t(:your_preferences_have_been_updated)
    end
    @user = User.find(current_user.id)
  end

  def site_settings
    @page_header = I18n.t("site_settings_menu")
    @user = User.find(current_user.id)
    if params[:generate_api_key]
      @user = alter_current_user do |user|
        user.update_attributes({ :api_key => User.generate_key })
      end
      params[:anchor] = "profile_api_key"
      flash[:notice] =  I18n.t(:your_preferences_have_been_updated)
    elsif params[:user] && request.post?
      current_user.log_activity(:updated_profile)
      @user = alter_current_user do |user|
        user.update_attributes(params[:user])
      end
      flash[:notice] =  I18n.t(:your_preferences_have_been_updated)
    end
  end

  # AJAX call to check if name is unique from signup page
  def check_username
    username = params[:username] || ""
    if User.unique_user?(username) || (logged_in? && current_user.username == username)
      message = ""
    else
      message =  I18n.t(:username_taken , :name => username)
    end
    render :update do |page|
      page.replace_html 'username_warn', message
    end
  end

  # AJAX call to check if email is unique from signup page
  def check_email
    email = params[:email] || ""
    if User.unique_email?(email) || (logged_in? && current_user.email == email)
      message = ""
    else
      message =  I18n.t(:username_taken , :name => email)
    end
    render :update do |page|
      page.replace_html 'email_warn', message
    end
  end

private
#  def main_if_not_logged_in
#    layout = current_user.username.nil? ? 'main' : 'user_profile'
#  end

  def password_length_okay?
    return !(params[:user][:entered_password].length < 4 || params[:user][:entered_password].length > 16)
  end

  def delete_password_reset_token(user)
    user.update_attributes(:password_reset_token => nil, :password_reset_token_expires_at => nil) if user
  end

  def go_to_forgot_password(user)
    flash[:notice] =  I18n.t(:expired_reset_password_link)
    delete_password_reset_token(user)
    redirect_to :action => "forgot_password", :protocol => "http"
  end

  # Change password parameters when they are set automatically by an autofil password management of a browser (known behavior of Firefox for example)
  def unset_auto_managed_password
    password = params[:user][:entered_password].strip
    if params[:user][:entered_password_confirmation].blank? && !password.blank? && User.hash_password(password) == User.find(current_user.id).hashed_password
      params[:user][:entered_password] = ''
    end
  end

#  def password_authentication(username, password, remember_me)
#    success, message_or_user = User.authenticate(username, password)
#    if success
#      successful_login(message_or_user, remember_me)
#    else
#      failed_login(message_or_user)
#    end
#  end
#
#  def successful_login(user, remember_me)
#    set_current_user(user)
#    notice_message =  I18n.t(:logged_in)
#    if remember_me && !user.is_admin?
#      user.remember_me
#      cookies[:user_auth_token] = { :value => user.remember_token , :expires => user.remember_token_expires_at }
#    elsif remember_me && user.is_admin?
#      notice_message +=  I18n.t(:admin_remind_me_message)
#    end
#    flash[:notice] = notice_message
#    if user.is_admin? && ( session[:return_to].nil? || session[:return_to].empty?) # if we're an admin we STILL would love a return, thank you very much!
#      redirect_to :controller => 'admin', :action => 'index', :protocol => "http://"
#    else
#      redirect_back_or_default
#    end
#  end
#
#  def failed_login(message)
#    flash[:warning] = message
#    redirect_to :action => 'login'
#  end
end
