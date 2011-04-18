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
    # Whitelisting redirection to our own site, relative paths.
    params[:return_to] = nil unless params[:return_to] =~ /\A[%2F\/]/

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
      current_user.id = nil
      store_location(params[:return_to]) unless params[:return_to].nil? # store the page we came from so we can return there if it's passed in the URL
      return
    end

    set_curator_clade(params)

    # create a new user with the defaults and then update with the user entered values on the signup form
    @user = User.create_new(params[:user])

    # no initial roles for a new web user
    @user.roles = []

    # give them a validation code and make their account not active by default
    @user.validation_code = Digest::MD5.hexdigest "#{@user.username}#{Time.now.hour}:#{Time.now.min}:#{Time.now.sec}"
    while(User.find_by_validation_code(@user.validation_code))
      @user.validation_code.succ!
    end
    @user.active = false

    # set the password and the remote_IP address
    @user.password = @user.entered_password
    @user.remote_ip = request.remote_ip
    if verify_recaptcha &&  @user.save
      begin
        @user.update_attribute :agent_id, Agent.create_agent_from_user(@user.full_name).id
      rescue ActiveRecord::StatementInvalid
        # Interestingly, we are getting users who already have agents attached to them.  I'm not sure why, but it's causing registration to fail (or seem to; the user is created), and this is bad.
      end
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
    User.with_master do
      @user = User.find_by_username_and_validation_code(params[:id],params[:validation_code])
    end
    if !@user.blank?
      @user.update_attributes(:active => true) # activate their account
      Notifier.deliver_welcome_registration(@user) # send them a welcome message
    end
  end

  def logout
    # Whitelisting redirection to our own site, relative paths.
    params[:return_to] = nil unless params[:return_to] =~ /\A[%2F\/]/
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
      @user.expertise = current_user.expertise.to_s
      store_location(params[:return_to]) unless params[:return_to].nil? # store the page we came from so we can return there if it's passed in the URL
      current_user.log_activity(:profile)
      return
    end

    user_params = params[:user]
    unset_auto_managed_password
    if password_looks_like_it_changed?
      unless password_length_okay?
        current_user.errors.add_to_base("Password length must be between 4 and 16 characters."[:password_must_be_4to16_characters])
        return
      end
      current_user.password = user_params[:entered_password]
    end

    # The UI would not allow this, but a hacker might try to grant curator permissions to themselves in this manner.
    user_params.delete(:curator_approved) unless is_user_admin?

    set_curator_clade(params)

    current_user.log_activity(:updated_profile)

    alter_current_user do |user|
      user.update_attributes(user_params)
    end
    @user = current_user
    user_changed_mailing_list_settings(old_user,@user) if (old_user.mailing_list != @user.mailing_list) || (old_user.email != @user.email)
    flash[:notice] = "Your preferences have been updated."[:your_preferences_have_been_updated]
    redirect_back_or_default

  end

  # AJAX call to check if name is unique from signup page
  def check_username

    username = params[:username] || ""
    if User.unique_user?(username) || (logged_in? && current_user.username == username)
      message = ""
    else
      message = "{name} is already taken"[:username_taken,username]
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
      message = "{email} is already taken"[:username_taken,email]
    end

    render :update do |page|
      page.replace_html 'email_warn', message
    end

  end

  def show
    @user = User.find(params[:id])
    current_user.log_activity(:show_user_id, :value => params[:id])
    @user_submitted_text_count = UsersDataObject.count(:conditions=>['user_id = ?',params[:id]])
    redirect_back_or_default unless @user.curator_approved
  end

  def show_objects_curated
    page = (params[:page] || 1).to_i
    @user = User.find(params[:id])
    current_user.log_activity(:show_objects_curated_by_user_id, :value => params[:id])
    @latest_curator_actions = @user.actions_histories_on_data_objects.paginate_all_by_action_with_object_id(
                                ActionWithObject.raw_curator_action_ids,
                                :select => 'actions_histories.*, action_with_objects.action_code',
                                :order => 'actions_histories.updated_at DESC',
                                :group => 'actions_histories.object_id',
                                :include => [ :action_with_object ],
                                :page => page, :per_page => @@objects_per_page)
    @curated_datos = DataObject.find(@latest_curator_actions.collect{|lca| lca[:object_id]},
                       :select => 'data_objects.id, data_objects.description, data_objects.object_cache_url, ' +
                                  'vetted.label, visibilities.label, table_of_contents.label, ' +
                                  'hierarchy_entries.taxon_concept_id, hierarchy_entries.published, ' +
                                  'taxon_concepts.*, names.italicized' ,
                       :include => [ :vetted, :visibility, :toc_items,
                                     { :hierarchy_entries => [ :taxon_concept, :name ] } ])
    @latest_curator_actions.each do |ah|
      dato = @curated_datos.detect {|item| item[:id] == ah[:object_id]}
      # We use nested include of hierarchy entries, taxon concept and names as a first cheap
      # attempt to retrieve a scientific name.
      dato.hierarchy_entries.each do |he|
        # TODO: Check to see if this is using eager loading or not!
        if he.taxon_concept[:published] == 1 then
          dato[:_preferred_name_italicized] = he.name[:italicized]
          dato[:_preferred_taxon_concept_id] = he.taxon_concept_id
          break
        end
      end

      if dato[:_preferred_taxon_concept_id].nil? then
        # Hierarchy entries have not given us a published taxon concept so either the concept has been superceded
        # or its a user submitted data object, either way we go on a hunt for a published taxon concept with some
        # expensive queries.
        tcs = dato.get_taxon_concepts(:published => :preferred)
        tc = tcs.detect{|item| item[:published] == 1}
        # We only add a preferred taxon concept id if we've found a published taxon concept.
        dato[:_preferred_taxon_concept_id] = tc.nil? ? nil : tc[:id]
        # Finally we find a name, first we try cheaper hierarchy entries, if that fails we try through taxon concepts.
        dato[:_preferred_name_italicized] = dato.hierarchy_entries.first.name[:italicized] unless dato.hierarchy_entries.first.nil?
        if dato[:_preferred_name_italicized].nil? then
          tc = tcs.first if tc.nil? # Grab the first unpublished taxon concept if we didn't find a published one earlier.
          dato[:_preferred_name_italicized] = tc.nil? ? nil : tc.quick_scientific_name(:italicized)
        end
      end

      dato[:_description_teaser] = ""
      unless dato.description.blank? then
        dato[:_description_teaser] = Sanitize.clean(dato.description, :elements => %w[b i],
                                                    :remove_contents => %w[table script])
        dato[:_description_teaser] = dato[:_description_teaser].split[0..80].join(' ').balance_tags +
                                     '...' if dato[:_description_teaser].length > 500
      end

    end
  end

  def show_species_curated
    page = (params[:page] || 1).to_i
    @user = User.find(params[:id])
    current_user.log_activity(:show_species_curated_by_user_id, :value => params[:id])
    @taxon_concept_ids = @user.taxon_concept_ids_curated.paginate(:page => page, :per_page => @@objects_per_page)
  end

  def show_comments_moderated
    page = (params[:page] || 1).to_i
    @user = User.find(params[:id])
    current_user.log_activity(:show_species_comments_moderated_by_user_id, :value => params[:id])
    @all_comments = @user.comments_curated
    @comments = @all_comments.paginate(:page => page, :per_page => @@objects_per_page)
  end


  # this is the uservoice single sign on redirect
  def uservoice_login
    token = current_user.uservoice_token
    current_user.log_activity(:uservoice_login)
    redirect_to "#{$USERVOICE_URL}?sso=#{token}"
  end

private

  def password_looks_like_it_changed?
    return !(params[:user][:entered_password].blank? && params[:user][:entered_password_confirmation].blank?)
  end

  def password_length_okay?
    return !(params[:user][:entered_password].length < 4 || params[:user][:entered_password].length > 16)
  end

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
    notice_message = "Logged in successfully."[:logged_in]
    if remember_me && !user.is_admin?
      user.remember_me
      cookies[:user_auth_token] = { :value => user.remember_token , :expires => user.remember_token_expires_at }
    elsif remember_me && user.is_admin?
      notice_message += " NOTE: for security reasons, administrators cannot use the remember me feature."[:admin_remind_me_message]
    end
    flash[:notice] = notice_message
    if user.is_admin? && ( session[:return_to].nil? || session[:return_to].empty?) # if we're an admin we STILL would love a return, thank you very much!
      redirect_to :controller => 'admin', :action => 'index', :protocol => "http://"
    else
      redirect_back_or_default
    end
  end

  def failed_login(message)
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
  def user_changed_mailing_list_settings(old_user,new_user)
    media_inquiry_subject = ContactSubject.find_by_id($MEDIA_INQUIRY_CONTACT_SUBJECT_ID)
    if media_inquiry_subject.nil?
      recipient = "test@eol.org"
    else
      recipient = media_inquiry_subject.recipients
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
