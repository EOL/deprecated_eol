class UsersController < ApplicationController

  include EOL::Login

  layout :users_layout

  before_filter :redirect_if_already_logged_in, only: [:new, :create, :verify, :pending, :activated,
                                                          :recover_account, :temporary_login]
  before_filter :check_user_agreed_with_terms, except: [:terms_agreement, :temporary_login, :usernames]
  before_filter :extend_for_open_authentication, only: [:new, :create]
  before_filter :restrict_to_admins, only: [:scrub]

  rescue_from OAuth::Unauthorized, with: :oauth_unauthorized_rescue
  rescue_from EOL::Exceptions::OpenAuthUnauthorized, with: :oauth_unauthorized_rescue

  @@objects_per_page = 20

  # GET /users/:id
  def show
    @user = User.find(params[:id])
    clear_session_partial
    preload_user_associations
    redirect_if_user_is_inactive
    # TODO: User inactive versus user hidden is confusing.
    # TODO: Why are we continuing with show if user is inactive?
    # TODO: Why are we not redirecting if user is hidden?
    # TODO: Why are we showing no longer active message for hidden user? Rather than hidden message? Are they they same thing? If so why do we have both?
    if @user.is_hidden?
      flash[:notice] = I18n.t(:user_no_longer_active_message)
    end
    count_submitted_objects
    adjust_common_names_counts
    @rel_canonical_href = user_url(@user)
  end
  
  def count_submitted_objects
    @user_submitted_text_count = Rails.cache.fetch("users/count_submitted_objects/#{@user.id}", expires_in: 24.hours) do
      User.count_submitted_datos(@user.id)
    end
  end
  
  def adjust_common_names_counts
    @common_names_added = Rails.cache.fetch("users/common_names_added/#{@user.id}", expires_in: 24.hours) do
      Curator.total_objects_curated_by_action_and_user(Activity.add_common_name.id, @user.id, [ChangeableObjectType.synonym.id])
    end
    @common_names_removed = Rails.cache.fetch("users/common_names_removed/#{@user.id}", expires_in: 24.hours) do
    Curator.total_objects_curated_by_action_and_user(Activity.remove_common_name.id, @user.id, [ChangeableObjectType.synonym.id])
    end
    @common_names_curated = Rails.cache.fetch("users/common_names_curated/#{@user.id}", expires_in: 24.hours) do
      Curator.total_objects_curated_by_action_and_user([Activity.trust_common_name.id, Activity.untrust_common_name.id, Activity.unreview_common_name.id, Activity.inappropriate_common_name.id], @user.id, [ChangeableObjectType.synonym.id])
    end
  end
  
  def reindex
    @user = User.find(params[:id])
    update_counts
    flash[:notice]= I18n.t(:user_count_reindexed)
    respond_to do |format|
      format.html do
        redirect_to user_path(@user)
      end
      format.js do
        convert_flash_messages_for_ajax
        render partial: 'shared/flash_messages', layout: false # JS will handle rendering these.
      end
    end
  end

  # GET /users/:id/edit
  def edit
    @user = User.find(params[:id], include: :open_authentications)
    
    raise EOL::Exceptions::SecurityViolation.new("User with ID=#{current_user.id} does not have edit access to User with ID=#{@user.id}",
    :error_editing_someone_account) unless current_user.can_update?(@user)
    redirect_if_user_is_inactive
    flash.now[:notice] = I18n.t(:warning_you_are_editing_as_admin) if current_user.id != @user.id
    instantiate_variables_for_edit
  end

   # GET /users/:id/curation_privileges
  def curation_privileges
    @user = User.find(params[:id])
    
    raise EOL::Exceptions::SecurityViolation.new("User with ID=#{current_user.id} does not have edit access to User with ID=#{@user.id}",
    :error_editing_someone_account) unless current_user.can_update?(@user)
    instantiate_variables_for_curation_privileges
  end

  # PUT /users/:id
  def update
    @user = User.find(params[:id])
    
    raise EOL::Exceptions::SecurityViolation.new("User with ID=#{current_user.id} does not have edit access to User with ID=#{@user.id}",
    :error_editing_someone_account)unless current_user.can_update?(@user)
    redirect_to curation_privileges_user_path(@user), status: :moved_permanently and return if params[:commit_curation_privileges_get]
    redirect_to edit_user_notification_path(@user), status: :moved_permanently and return if params[:commit_notification_settings_get]
    generate_api_key and return if params[:commit_generate_api_key]
    unset_auto_managed_password if params[:user][:entered_password]
    if (requested_curator_level_id = params[:user][:requested_curator_level_id]) && requested_curator_level_id.to_i != @user.requested_curator_level_id && requested_curator_level_id.to_i != @user.curator_level_id
      params[:user][:requested_curator_at] = Time.now
    end
    user_before_update = @user
    if @user.update_attributes(params[:user])
      update_current_language(@user.language)
      upload_logo(
        @user,
        name: params[:user][:logo].original_filename
      ) unless params[:user][:logo].blank?
      store_location params[:return_to] if params[:return_to]
      provide_feedback
      redirect_back_or_default @user
    else
      failed_to_update_user
    end
  end

  def make_editor
    @user = User.find(params[:id])
    @notices = []
    @errors = []
    params[:collection_id].each do |id|
      collection = Collection.find(id)
      if collection.watch_collection?
        @errors << I18n.t(:error_watch_collections_cannot_be_shared)
      elsif collection && current_user.can_edit_collection?(collection)
        collection.users << @user
        # NOTE this is dangerous!  If I go and add EVERYONE to my
        # collection as an editor, I'm essentially spamming them:
        @user.watch_collection.add(collection)
        CollectionActivityLog.create(collection: collection, user: @user,
                                     activity: Activity.add_editor)
        @notices << I18n.t(:user_was_added_as_editor_of_collection,
                           collection: self.class.helpers.link_to(collection.name, collection_path(collection)))
      else
        @errors << I18n.t(:error_couldnt_find_collection_by_id, id: id)
      end
    end
    flash.now[:errors] = @errors.to_sentence unless @errors.empty?
    flash[:notice] = @notices.to_sentence unless @notices.empty?
    respond_to do |format|
      format.html { redirect_to @user, status: :moved_permanently }
      format.js do
        convert_flash_messages_for_ajax
        render partial: 'shared/flash_messages', layout: false # JS will handle rendering these.
      end
    end
  end

  def revoke_editor
    @user = User.find(params[:id])
    collection = Collection.find(params[:collection_id])
    raise EOL::Exceptions::ObjectNotFound unless collection
    
    raise EOL::Exceptions::SecurityViolation.new("User attempted to revoke editor on watch collection", :error_revoking_editor_on_watch_collection) if collection.watch_collection?
    @user.collections.delete(collection)
    flash[:notice] = I18n.t(:user_no_longer_has_manager_access_to_collection, user: @user.username,
                            collection: collection.name)
    respond_to do |format|
      format.html { redirect_to @user, status: :moved_permanently }
      format.js do
        convert_flash_messages_for_ajax
        render partial: 'shared/flash_messages', layout: false # JS will handle rendering these.
      end
    end
  end

  # GET /users/register
  # Extended by EOL::OpenAuth::ExtendUsersController
  def new
    # Clear open authentication tokens from when users cancels the complete registration form.
    session.delete_if{|k,v| k.to_s.match /^oauth_(token|secret)/}
    @user = User.new
  end

  # POST /users
  # Extended by EOL::OpenAuth::ExtendUsersController
  def create
    @user = User.new(params[:user].reverse_merge(language: current_language))
    failed_to_create_user and return unless @user.valid? && verify_recaptcha
    # TODO: WHY IS THIS IN THE @#$&*ING CONTROLLER?!?
    @user.validation_code = User.generate_key
    while(User.find_by_validation_code(@user.validation_code))
      @user.validation_code.succ!
    end
    @user.active = false
    @user.remote_ip = request.remote_ip
    if @user.save
      @user.clear_entered_password
      send_verification_email
      EOL::GlobalStatistics.increment('users')
      redirect_to pending_user_path(@user), status: :moved_permanently
    else
      failed_to_create_user and return
    end
  end

  # GET named route /users/:user_id/verify/:validation_code
  # users come here from the activation email they receive after registering with EOL credentials
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
      redirect_to login_path, status: :moved_permanently
    elsif @user && @user.validation_code == params[:validation_code] && !params[:validation_code].blank?
      @user.activate
      Notifier.user_activated(@user).deliver
      flash[:notice] = I18n.t(:user_activation_successful_notice, username: @user.username)
      session[:conversion_code] = User.generate_key
      redirect_to activated_user_path(@user, success: session[:conversion_code]), status: :moved_permanently
    elsif @user
      @user.validation_code = User.generate_key if @user.validation_code.blank?
      send_verification_email
      flash[:error] = I18n.t(:user_activation_failed_resent_validation_email_error)
      redirect_to pending_user_path(@user), status: :moved_permanently
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
    conversion_code = session.delete(:conversion_code)
    if (params[:success] == conversion_code) && (conversion_code =~ /^[0-9a-f]{40}$/)
      @conversion = EOL::GoogleAdWords.create_signup_conversion
    end
    @user = User.find(params[:id], include: :open_authentications)
  end

  # GET and POST for member /users/:id/terms_agreement
  def terms_agreement
    @user = User.find(params[:id])
    
    raise EOL::Exceptions::SecurityViolation.new("User with ID=#{current_user.id} does not have permission to access terms agreement"\
      " for User with ID=#{@user.id}", :error_editing_someone_account) unless current_user.can_update?(@user)
    if request.post? && params[:commit_agreed]
      @user.update_column(:agreed_with_terms, true) # saving without validation to avoid issues with invalid legacy users
      @user.expire_primary_index
      # validation will more appropriately happen when user attempts to edit profile
      redirect_back_or_default(user_path(current_user))
    else
      page = ContentPage.find_by_page_name('terms_of_use')
      unless page.nil?
        @terms = TranslatedContentPage.find_by_content_page_id_and_language_id_and_active_translation(page, @user.language.id, 1)
        @terms = TranslatedContentPage.find_by_content_page_id_and_language_id_and_active_translation(page, Language.english.id, 1) if @terms.blank?
      end
    end
  end

  # NOTE - this is slightly silly, but the JS plugin we're using really does want all usernames in one call.
  def usernames
    usernames = Rails.cache.fetch('users/usernames', expires_in: 55.minutes) do
      User.all(select: 'username', conditions: 'active = 1').map {|u| u.username }
    end
    render text: usernames.to_json
  end

  def pending_notifications
    Periodically::Immediately.prepare_notifications
    Periodically::Immediately.send_notifications
  end

  # GET /users/:user_id/unsubscribe_notifications/:key
  def unsubscribe_notifications
    if @user = User.find(params[:user_id])
      if params[:key] == @user.unsubscribe_key
        begin
          already_unsubscribed = true
          User.find_all_by_email(@user.email).each do |u|
            u.disable_email_notifications = true
            if u.changed?
              u.save
              already_unsubscribed = false
            end
          end
          if already_unsubscribed
            flash[:notice] = I18n.t(:already_unsubscribed, scope: [:users, :unsubscribe_notifications])
          else
            send_unsubscribed_to_notifications_email
            flash[:notice] = I18n.t(:unsubscribed_notifications_successfully, scope: [:users, :unsubscribe_notifications])
          end
        rescue
          flash[:error] = I18n.t(:unsubscribe_notifications_failed, scope: [:users, :unsubscribe_notifications])
        end
        return redirect_back_or_default
      else
        access_denied
      end
    else
      access_denied
    end
  end

  # GET /users/verify_open_authentication
  # Third-party apps redirect here from authorization screens, when existing users request to add connected accounts
  def verify_open_authentication
    
    raise EOL::Exceptions::SecurityViolation.new("We got an authorization callback from a third-party app to add a connected account,"\
      "but we don't have a current user account to add it to, as no one is logged in.", :must_be_logged_in) unless logged_in?
    params.delete(:controller)
    params.delete(:action)
    redirect_to new_user_open_authentication_url(params.merge({user_id: current_user.id}))
  end

  # GET and POST for :collection route /users/recover_account
  def recover_account
    if request.post? && params[:user]
      if params[:commit_choose_account]
        user = User.find(params[:user][:id]) rescue nil
        if user.nil?
          @users = User.find_all_by_email(params[:user][:email].strip)
          flash.now[:error] = I18n.t('users.recover_account_choose_account.errors.user_not_found_choose_again')
          render action: 'recover_account_choose_account' and return
        end
      else
        @users = User.find_all_by_email(params[:user][:email].strip)
        if @users.blank?
          flash.now[:error] = I18n.t('users.recover_account.errors.user_not_found_by_email_address')
          return
        elsif @users.size > 1
          render action: 'recover_account_choose_account' and return
        end
        user = @users.first
      end
      if user.hidden?
        
        raise EOL::Exceptions::SecurityViolation.new(
          "Hidden User with ID=#{user.id} attempted to recover their account and was disallowed.",
          :hidden_user_recover_account)
      end

      # Bypass validation errors on user model
      user.update_column(:recover_account_token, User.generate_key)
      user.update_column(:recover_account_token_expires_at, 24.hours.from_now)
      user.expire_primary_index
      user.reload # Just to ensure everything is dandy in the database (TODO: will slave cause problems?)
      if user.recover_account_token =~ /^[a-f0-9]{40}$/ && !user.recover_account_token_expired?
        Notifier.user_recover_account(user, temporary_login_user_url(user, user.recover_account_token)).deliver
        flash[:notice] = I18n.t('users.recover_account.notices.recovery_email_sent', from_address: $NO_REPLY_EMAIL_ADDRESS)
        redirect_to login_path and return
      else
        flash.now[:error] = I18n.t('users.recover_account.errors.unable_to_update_token')
      end
    end
  end

  # GET for named route /users/:user_id/temporary_login/:recover_account_token
  def temporary_login
    user = User.find(params[:user_id])
    if user.nil?
      flash[:error] = I18n.t('users.recover_account.errors.temporary_login_user_not_found')
    else
      if user.hidden?
        
        raise EOL::Exceptions::SecurityViolation.new(
          "Hidden User with ID=#{user.id} attempted to use a temporary login link and was disallowed.",
          :hidden_user_temporary_login)
      end
      if user.recover_account_token_matches?(params[:recover_account_token]) && !user.recover_account_token_expired?
        user.update_column(:recover_account_token, nil)
        user.update_column(:recover_account_token_expires_at, nil)
        user.expire_primary_index
        unless user.active?
          # Treat this as email verification for inactive users
          user.activate
          Notifier.user_activated(user).deliver
        end
        log_in(user)
        flash[:notice] = I18n.t('users.recover_account.notices.temporarily_logged_in_update_authentication_details')
        redirect_to edit_user_path(user), status: :moved_permanently and return
      else
        if user.recover_account_token_expired?
          user.update_column(:recover_account_token, nil)
          user.update_column(:recover_account_token_expires_at, nil)
          user.expire_primary_index
        end
        flash[:error] =  I18n.t('users.recover_account.errors.token_expired_or_invalid')
      end
    end
    redirect_to recover_account_users_path
  end

  def grant_permission
    user = User.find(params[:id])
    @permission = Permission.find(params[:permission_id])
    raise EOL::Exceptions::ObjectNotFound unless @permission
    
    raise EOL::Exceptions::SecurityViolation.new("User with id = #{current_user.id} tried to grant permission with id = #{params[:permission_id]}",
    :can_not_edit_permissions) unless current_user.can?(:edit_permissions)
    user.grant_permission(@permission)
    respond_to do |format|
      format.html do
        redirect_to user, status: :moved_permanently
        flash[:notice] = I18n.t(:permission_granted)
      end
      format.js { }
    end
  end

  def revoke_permission
    @user = User.find(params[:id])
    @permission = Permission.find(params[:permission_id])
    raise EOL::Exceptions::ObjectNotFound unless @permission
    
    raise EOL::Exceptions::SecurityViolation.new("User with id = #{current_user.id} tried to grant permission with id = #{params[:permission_id]}",
    :can_not_edit_permissions) unless current_user.can?(:edit_permissions)
    @user.revoke_permission(@permission)
    respond_to do |format|
      format.html do
        redirect_to @user, status: :moved_permanently
        flash[:notice] = I18n.t(:permission_revoked)
      end
      format.js { }
    end
  end

  def scrub
    @user = User.find params[:id]
    @user.scrub!(current_user)
    update_counts
    clear_cached_homepage_activity_logs
    redirect_to @user, notice: I18n.t(:scrub_user_notice)
  end
protected

  def scoped_variables_for_translations
    @scoped_variables_for_translations ||= super.dup.merge({
      user_full_name: @user ? @user.full_name.presence : nil,
      curator_level: @user && @user.curator_level ? @user.curator_level.translated_label : nil
    }).freeze
  end

  def meta_description
    return @meta_description if defined?(@meta_description)
    translation_vars = scoped_variables_for_translations.dup
    @meta_description = translation_vars[:curator_level].blank? ?
      t(".meta_description", translation_vars) :
      t(".meta_description_curator", translation_vars.merge({default: t(".meta_description", translation_vars)}))
  end

  def meta_open_graph_image_url
    @meta_open_graph_image_url ||= @user &&
      view_context.image_tag(
        @user.logo_url(linked?: true)
      )
  end

  def clear_session_partial
    if @user && @user == current_user
      expire_fragment("sessions_#{current_user.id}")
    end
  end

# NOTE - there are a few "protected" methods above, be careful.
private

  def update_counts
    cache_keys = [:common_names_added, :common_names_removed, :common_names_curated, :total_species_curated, :total_user_objects_curated,
    :total_user_exemplar_images, :total_user_overview_articles, :total_user_preferred_classifications, :count_taxa_commented, :count_submitted_objects, :count_total_data_records]
    cache_keys.each do |key|
      Rails.cache.delete("users/#{key}/#{@user.id}")
    end
    #call reindex methods
    count_submitted_objects
    adjust_common_names_counts
    @user.total_species_curated
    @user.total_user_objects_curated
    @user.total_user_exemplar_images
    @user.total_user_overview_articles
    @user.total_user_preferred_classifications
    @user.count_taxa_commented
    @user.count_total_data_records
  end

  def extend_for_open_authentication
    self.extend(EOL::OpenAuth::ExtendUsersController) if params[:oauth_provider] ||
      (! params[:user].nil? && ! params[:user][:open_authentications_attributes].blank?)
  end

  def oauth_unauthorized_rescue
    error_scope = [:users, :open_authentications, :errors]
    error_scope << @open_auth.provider if !@open_auth.nil? && !@open_auth.provider.nil?
    if logged_in?
      flash[:error] = I18n.t(:not_authorized_to_add_authentication, scope: error_scope)
      redirect_to user_open_authentications_url(current_user)
    else
      flash[:error] = I18n.t(:not_authorized_to_signup, scope: error_scope)
      redirect_to new_user_url
    end
  end

  def users_layout # choose an appropriate views layout for an action
    case action_name
    when 'recover_account', 'terms_agreement', 'new', 'pending', 'activated'
      'sessions'
    when 'curation_privileges'
      'basic'
    else
      'users'
    end
  end

  def failed_to_create_user
    @user.clear_entered_password if @user
    flash.now[:error] = I18n.t(:create_user_unsuccessful_error)
    flash.now[:error] << I18n.t(:recaptcha_incorrect_error_with_anchor, recaptcha_anchor: 'recaptcha_widget_div') unless verify_recaptcha
    render action: :new, layout: 'sessions'
  end

  def failed_to_update_user
    @user.clear_entered_password if @user
    flash.now[:error] = I18n.t(:update_user_unsuccessful_error)
    if params[:commit_curation_privileges_put]
      instantiate_variables_for_curation_privileges
      render :curation_privileges, layout: 'basic'
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
    Notifier.user_verification(@user, verify_user_url(@user.id, @user.validation_code)).deliver
  end

  def send_unsubscribed_to_notifications_email
    Notifier.deliver_unsubscribed_to_notifications(@user)
  end

  def send_unsubscribed_to_notifications_email
    Notifier.deliver_unsubscribed_to_notifications(@user)
  end

  def generate_api_key
    @user.clear_entered_password
    @user.generate_api_key
    @user.save!
    instantiate_variables_for_edit
    render :edit
  end

  def instantiate_variables_for_edit
    @user_identities = UserIdentity.find(:all, order: "sort_order ASC")
  end

  def instantiate_variables_for_curation_privileges
    @curator_levels = CuratorLevel.find(:all, order: "label ASC")
    @page_title = I18n.t(:curation_privileges_page_title)
    @page_description = I18n.t(:curation_privileges_page_description, curators_url: curators_path)
  end

  def provide_feedback
    if params[:commit_curation_privileges_put]
      case params[:user][:requested_curator_level_id].to_i
      when CuratorLevel.assistant.id
        flash[:notice] = I18n.t(:curator_level_assistant_approved_notice, more_url: curators_path)
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

  # TODO - DO WE STILL NEED THIS?  ...I don't think we do.  (?)  I created a method to give Marie a list of all the
  # users who need an email, and I don't think she needs to get individual emails anymore.

  def user_updated_email_preferences?(user_before_update, user_after_update)
    if user_after_update.has_attribute?(:mailing_list) # TODO - superfluous, remove.
      user_before_update.mailing_list != user_after_update.mailing_list || user_before_update.email != user_after_update.email
    else
      false
    end
  end

  def send_preferences_updated_email(user_before_update, user_after_update)
    media_inquiry_subject = ContactSubject.find_by_id($MEDIA_INQUIRY_CONTACT_SUBJECT_ID)
    if media_inquiry_subject.nil?
      recipient = $SPECIES_PAGES_GROUP_EMAIL_ADDRESS
    else
      recipient = media_inquiry_subject.recipients
    end
    Notifier.user_updated_email_preferences(user_before_update, user_after_update, recipient).deliver
  end

  def preload_user_associations
    # used to count the collections and communities in the menu
    User.preload_associations(@user, [ :collections_including_unpublished, { members: { community: :collections } } ] )
  end

  def redirect_if_user_is_inactive
    unless @user.active
      flash[:notice] = I18n.t(:user_no_longer_active_message)
      redirect_back_or_default
    end
  end

end
