class UsersController < ApplicationController

  layout :users_layout

  before_filter :authentication_only_allow_editing_of_self, :only => [:edit, :update, :terms_agreement, :curation_privileges]
  before_filter :redirect_if_already_logged_in, :only => [:new, :create, :verify, :pending, :activated,
                                                          :forgot_password, :reset_password]
  before_filter :check_user_agreed_with_terms, :except => [:terms_agreement, :reset_password, :usernames]

  @@objects_per_page = 20

  # GET /users/:id
  def show
    @user = User.find(params[:id])
    if @user.is_hidden?
      flash[:notice] = I18n.t(:user_hidden_message)
    end
    @user_submitted_text_count = UsersDataObject.count(:conditions => ['user_id = ?',params[:id]])
  end

  # GET /users/:id/edit
  def edit
    # @user instantiated by authentication before filter and matched to current user
    instantiate_variables_for_edit
  end

   # GET /users/:id/curation_privileges
  def curation_privileges
    # @user instantiated by authentication before filter and matched to current user
    instantiate_variables_for_curation_privileges
  end

  # PUT /users/:id
  def update
    # @user instantiated by authentication before filter and matched to current user
    redirect_to curation_privileges_user_path(@user) and return if params[:commit_curation_privileges_get]
    generate_api_key and return if params[:commit_generate_api_key]
    unset_auto_managed_password if params[:user][:entered_password]
    user_before_update = @user
    if @user.update_attributes(params[:user])
      # not using alter_current_user because it doesn't allow for validation checks
      # and we probably don't want to update current_user with invalid attributes
      upload_logo(@user) unless params[:user][:logo].blank?
      $CACHE.delete("users/#{session[:user_id]}")
      set_current_user(@user)
      current_user.log_activity(:updated_user)
      store_location params[:return_to] if params[:return_to]
      provide_feedback
      send_preferences_updated_email(user_before_update, @user) if user_updated_email_preferences?(user_before_update, @user)
      redirect_back_or_default @user
    else
      failed_to_update_user
    end
  end

  # GET /users/register
  def new
    @user = User.new
  end

  # POST /users
  def create
    @user = User.create_new(params[:user])
    failed_to_create_user and return unless @user.valid? && verify_recaptcha
    @user.validation_code = User.generate_key
    while(User.find_by_validation_code(@user.validation_code))
      @user.validation_code.succ!
    end
    @user.active = false
    @user.remote_ip = request.remote_ip
    if @user.save
      @user.clear_entered_password
      begin
        # FIXME: Figure out whether we still need an agent to be created for a user in V2
        # If we do note that user does not have full_name on creation.
        @user.update_attributes(:agent_id => Agent.create_agent_from_user(@user.full_name).id)
      rescue ActiveRecord::StatementInvalid
        # Interestingly, we are getting users who already have agents attached to them.  I'm not sure why, but it's causing registration to fail (or seem to; the user is created), and this is bad.
      end
      send_verification_email
      EOL::GlobalStatistics.increment('users')
      redirect_to pending_user_path(@user)
    else
      failed_to_create_user and return
    end
  end

  # GET named route /users/:user_id/verify/:validation_code users come here from the activation email they receive after registering
  def verify
    user_id = params[:user_id] || 0
    User.with_master do
      # we need to first check for usernames as some people may have received the validation
      # link with the username before we changed the links to use user IDs on 10.26.2011
      @user = User.find_by_username(User.username_from_verify_url(user_id))
      # we couldn't find the user by username (we're searching for usernames matching the user_id parameter)
      # OR we did find a user, but it had a different validation code, so look it up by ID
      if user_id.is_numeric? && (!@user || (@user.validation_code && !params[:validation_code].blank? && @user.validation_code != params[:validation_code]))
        @user = User.find(user_id.to_i)
      end
    end
    if @user && @user.active
      flash[:notice] = I18n.t(:user_already_active_notice)
      redirect_to login_path
    elsif @user && @user.validation_code == params[:validation_code] && !params[:validation_code].blank?
      @user.activate
      Notifier.deliver_user_activated(@user)
      redirect_to activated_user_path(@user)
    elsif @user
      @user.validation_code = User.generate_key if @user.validation_code.blank?
      send_verification_email
      flash[:error] = I18n.t(:user_activation_failed_resent_validation_email_error)
      redirect_to pending_user_path(@user)
    else
      flash[:error] = I18n.t(:user_activation_failed_user_not_found_error)
      redirect_to new_user_path
    end
  end

  # GET for member /users/:id/pending
  def pending
    @user = User.find(params[:id])
  end

  # GET for member /users/:id/activated
  def activated
    @user = User.find(params[:id])
    flash.now[:notice] = I18n.t(:user_activation_successful_notice, :username => @user.username)
  end

  # GET and POST for member /users/:user_id/terms_agreement
  def terms_agreement
    # @user instantiated by authentication before filter and matched to current user
    access_denied unless current_user.can_update?(@user)
    if request.post? && params[:commit_agreed]
      @user.agreed_with_terms = true
      @user.save(false) # saving without validation to avoid issues with invalid legacy users
      # validation will more appropriately happen when user attempts to edit profile
      # avoiding alter_current_user as this would try to save again but fail if any validation issues
      if current_user.id == @user.id
        $CACHE.delete("users/#{session[:user_id]}")
        set_current_user(@user)
      end
      redirect_back_or_default(user_path(current_user))
    else
      page = ContentPage.find_by_page_name('terms_of_use')
      unless page.nil?
        @terms = TranslatedContentPage.find_by_content_page_id_and_language_id_and_active_translation(page, @user.language_id, 1)
        @terms = TranslatedContentPage.find_by_content_page_id_and_language_id_and_active_translation(page, Language.english.id, 1) if @terms.blank?
      end
    end
  end

  # GET and POST for named route /users/forgot_password
  def forgot_password
    if request.post?
      if params[:user][:username_or_email].blank?
        if params[:commit_choose_account]
          @users = User.find_all_by_email(params[:user][:email])
          flash.now[:error] = I18n.t(:forgot_password_form_choose_username_blank_error)
          render :action => 'forgot_password_choose_account'
        else
          flash.now[:error] = I18n.t(:forgot_password_form_username_or_email_blank_error)
        end
      else
        @username_or_email = params[:user][:username_or_email].strip
        @users = User.find_all_by_email(@username_or_email)
        @users = User.find_all_by_username(@username_or_email) if @users.empty?
        store_location(params[:return_to]) unless params[:return_to].nil? # store the page we came from so we can return there if it's passed in the URL
        if @users.size == 1
          user = @users[0]
          generate_password_reset_token(user)
          Notifier.deliver_user_reset_password(user, reset_password_user_url(user, user.password_reset_token))
          flash[:notice] =  I18n.t(:reset_password_instructions_sent_to_user_notice, :username => user.username)
          redirect_to login_path
        elsif @users.size > 1
          render :action => 'forgot_password_choose_account'
        else
          flash.now[:error] =  I18n.t(:forgot_password_cannot_find_user_from_username_or_email_error, :username_or_email => Sanitize.clean(params[:user][:username_or_email]))
        end
      end
    end
  end

  # GET for named route /users/:user_id/reset_password/:password_reset_token
  def reset_password
    password_reset_token = params[:password_reset_token]
    user = User.find_by_password_reset_token(password_reset_token)
    is_expired = Time.now > user.password_reset_token_expires_at if user && !user.password_reset_token_expires_at.blank?
    delete_password_reset_token(user) if is_expired
    if ! user || is_expired
      flash[:error] =  I18n.t(:reset_password_token_expired_error)
      redirect_to forgot_password_users_path
    else
      set_current_user(user)
      delete_password_reset_token(user)
      flash[:notice] = I18n.t(:reset_password_enter_new_password_notice)
      redirect_to edit_user_path(user)
    end
  end

  # NOTE - this is slightly silly, but the JS plugin we're using really does want all usernames in one call.
  def usernames
    usernames = $CACHE.fetch('users/usernames', :expires_in => 55.minutes) do
      User.all(:select => 'username', :conditions => 'active = 1').map {|u| u.username }
    end
    render :text => usernames.to_json
  end

private

  def users_layout # choose an appropriate views layout for an action
    case action_name
    when 'forgot_password', 'terms_agreement', 'new', 'pending', 'activated'
      'v2/sessions'
    when 'curation_privileges'
      'v2/basic'
    else
      'v2/users'
    end
  end

  def authentication_only_allow_editing_of_self
    @user = User.find(params[:id])
    access_denied unless current_user.id == @user.id
  end

  def generate_password_reset_token(user)
    new_token = User.generate_key
    user.update_attributes(:password_reset_token => new_token, :password_reset_token_expires_at => 24.hours.from_now)
  end

  def delete_password_reset_token(user)
    user.update_attributes(:password_reset_token => nil, :password_reset_token_expires_at => nil) if user
  end

  def failed_to_create_user
    @user.clear_entered_password if @user
    flash.now[:error] = I18n.t(:create_user_unsuccessful_error)
    flash.now[:error] << I18n.t(:recaptcha_incorrect_error_with_anchor, :recaptcha_anchor => 'recaptcha_widget_div') unless verify_recaptcha
    render :action => :new, :layout => 'v2/sessions'
  end

  def failed_to_update_user
    @user.clear_entered_password if @user
    flash.now[:error] = I18n.t(:update_user_unsuccessful_error)
    if params[:commit_curation_privileges_put]
      instantiate_variables_for_curation_privileges
      render :curation_privileges, :layout => 'v2/basic'
    else
      instantiate_variables_for_edit
      render :edit
    end
  end

  # Change password parameters when they are set automatically by an auto fill password management of a browser (known behavior of Firefox for example)
  def unset_auto_managed_password
    password = params[:user][:entered_password].strip
    if params[:user][:entered_password_confirmation].blank? && !password.blank? && User.hash_password(password) == User.find(current_user.id).hashed_password
      params[:user][:entered_password] = ''
    end
  end

  def send_verification_email
    Notifier.deliver_user_verification(@user, verify_user_url(@user.id, @user.validation_code))
  end

  def generate_api_key
    @user.clear_entered_password
    @user = alter_current_user do |user|
      user.update_attributes({ :api_key => User.generate_key })
    end
    instantiate_variables_for_edit
    render :edit
  end

  def instantiate_variables_for_edit
    @user_identities = UserIdentity.find(:all, :order => "sort_order ASC")
  end

  def instantiate_variables_for_curation_privileges
    @curator_levels = CuratorLevel.find(:all, :order => "label ASC")
    @page_title = I18n.t(:curation_privileges_page_title)
    @page_description = I18n.t(:curation_privileges_page_description, :curators_url => curators_path)
  end

  def provide_feedback
    if params[:commit_curation_privileges_put]
      case params[:user][:requested_curator_level_id].to_i
      when CuratorLevel.assistant.id
        flash[:notice] = I18n.t(:curator_level_assistant_approved_notice, :more_url => curators_path)
      when CuratorLevel.full.id
        flash[:notice] = I18n.t(:curator_level_full_pending_notice)
      when CuratorLevel.master.id
        flash[:notice] = I18n.t(:curator_level_master_pending_notice)
      else !@user.requested_curator_level_id.nil? && !@user.requested_curator_level_id.zero?
        flash[:notice] = I18n.t(:curator_level_application_pending_notice)
      end
    else
      flash[:notice] = I18n.t(:update_user_successful_notice)
    end
  end

  def user_updated_email_preferences?(user_before_update, user_after_update)
    user_before_update.mailing_list != user_after_update.mailing_list || user_before_update.email != user_after_update.email
  end

  def send_preferences_updated_email(user_before_update, user_after_update)
    media_inquiry_subject = ContactSubject.find_by_id($MEDIA_INQUIRY_CONTACT_SUBJECT_ID)
    if media_inquiry_subject.nil?
      recipient = $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
    else
      recipient = media_inquiry_subject.recipients
    end
    Notifier.deliver_user_updated_email_preferences(user_before_update, user_after_update, recipient)
  end

end
