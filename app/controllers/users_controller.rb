class UsersController < ApplicationController

  layout :users_layout

  before_filter :authentication_only_allow_editing_of_self, :only => [:edit, :update, :terms_agreement]
  before_filter :check_user_agreed_with_terms, :except => [:terms_agreement, :reset_password]
  before_filter :redirect_if_already_logged_in, :only => [:new, :create, :verify, :pending, :activated,
                                                          :forgot_password, :reset_password]

  @@objects_per_page = 20

  # GET /users/:id
  def show
    @user = User.find(params[:id])
  end

  # GET /users/:id/edit
  def edit
    # @user instantiated by authentication before filter and matched to current user
  end

  # PUT /users/:id
  def update
    # @user instantiated by authentication before filter and matched to current user
    unset_auto_managed_password
    generate_api_key and return if params[:commit_generate_api_key]
    if @user.update_attributes(params[:user])
      # not using alter_current_user because it doesn't allow for validation checks
      # and we probably don't want to update current_user with invalid attributes
      upload_logo(@user) unless params[:user][:logo].blank?
      $CACHE.delete("users/#{session[:user_id]}")
      set_current_user(@user)
      current_user.log_activity(:updated_user)
      redirect_to @user
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
#      begin # TODO: Figure out whether we still need an agent to be created for a user - note full_name doesn't exist
#        @user.update_attribute :agent_id, Agent.create_agent_from_user(@user.full_name).id # V2 users only required to add username on signup
#      rescue ActiveRecord::StatementInvalid
#        # Interestingly, we are getting users who already have agents attached to them.  I'm not sure why, but it's causing registration to fail (or seem to; the user is created), and this is bad.
#      end
      send_verification_email
      redirect_to pending_user_path(@user)
    else
      failed_to_create_user and return
    end
  end

  # GET named route /users/:username/verify/:validation_code users come here from the activation email they receive after registering
  def verify
    params[:username] ||= ''
    User.with_master do
      @user = User.find_by_username(params[:username])
    end
    if @user && @user.active
      flash[:notice] = I18n.t(:user_already_active_notice)
      redirect_to login_path
    elsif @user && @user.validation_code == params[:validation_code] && ! params[:validation_code].blank?
      @user.activate
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
  end

  # GET and POST for member /users/:user_id/terms_agreement
  def terms_agreement
    # @user instantiated by authentication before filter and matched to current user
    if request.post? && params[:commit_agreed]
      alter_current_user do |user|
        user.agreed_with_terms = true
      end
      redirect_back_or_default(user_path(current_user))
    else
      # FIXME: is this the right content for terms agreement and the right call for it?
      # FIXME: this seems flakey, do we have unique machine names for content rather than page name?
      page = ContentPage.find_by_page_name('Terms Of Use')
      @terms = TranslatedContentPage.find_by_content_page_id_and_language_id(page, @user.language_id) unless page.nil?
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
          Notifier.deliver_forgot_password_email(user, reset_password_url(user, user.password_reset_token))
          flash[:notice] =  I18n.t(:reset_password_instructions_sent_to_email_notice, :username => user.username, :email => user.email)
          redirect_to login_path
        elsif @users.size > 1
          render :action => 'forgot_password_choose_account'
        else
          flash.now[:error] =  I18n.t(:forgot_password_cannot_find_user_from_username_or_email_error, :username_or_email => params[:user][:username_or_email].strip.sanitize)
        end
      end
    end
  end

  # GET for named route /users/:user_id/reset_password/:password_reset_token
  def reset_password
    password_reset_token = params[:password_reset_token]
    user = User.find_by_password_reset_token(password_reset_token)
    is_expired = Time.now > user.password_reset_token_expires_at if user
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

#  def objects_curated
#    page = (params[:page] || 1).to_i
#    current_user.log_activity(:show_objects_curated_by_user_id, :value => params[:id])
#    @latest_curator_actions = @user.curator_activity_logs_on_data_objects.paginate_all_by_activity_id(
#                                Activity.raw_curator_action_ids,
#                                :select => 'curator_activity_logs.*',
#                                :order => 'curator_activity_logs.updated_at DESC',
#                                :group => 'curator_activity_logs.object_id',
#                                :include => [ :activity ],
#                                :page => page, :per_page => @@objects_per_page)
#    @curated_datos = DataObject.find(@latest_curator_actions.collect{|lca| lca[:object_id]},
#                       :select => 'data_objects.id, data_objects.description, data_objects.object_cache_url, ' +
#                                  'hierarchy_entries.taxon_concept_id, hierarchy_entries.published, ' +
#                                  'taxon_concepts.*, names.italicized' ,
#                       :include => [ :vetted, :visibility, :toc_items,
#                                     { :hierarchy_entries => [ :taxon_concept, :name ] } ])
#    @latest_curator_actions.each do |ah|
#      dato = @curated_datos.detect {|item| item[:id] == ah[:object_id]}
#      # We use nested include of hierarchy entries, taxon concept and names as a first cheap
#      # attempt to retrieve a scientific name.
#      # TODO - dato.hierarchy_entries does not account for associations created by (or untrusted by) curators.  That
#      # said, this whole method is too much code in a controller and should be re-written, so we are not (right now)
#      # going to fix this.  Please create the data in a model and display it in the view.
#      dato.hierarchy_entries.each do |he|
#        # TODO: Check to see if this is using eager loading or not!
#        if he.taxon_concept.published == 1 then
#          dato[:_preferred_name_italicized] = he.name.italicized
#          dato[:_preferred_taxon_concept_id] = he.taxon_concept_id
#          break
#        end
#      end
#
#      if dato[:_preferred_taxon_concept_id].nil? then
#        # Hierarchy entries have not given us a published taxon concept so either the concept has been superceded
#        # or its a user submitted data object, either way we go on a hunt for a published taxon concept with some
#        # expensive queries.
#        tcs = dato.get_taxon_concepts(:published => :preferred)
#        tc = tcs.detect{|item| item[:published] == 1}
#        # We only add a preferred taxon concept id if we've found a published taxon concept.
#        dato[:_preferred_taxon_concept_id] = tc.nil? ? nil : tc[:id]
#        # Finally we find a name, first we try cheaper hierarchy entries, if that fails we try through taxon concepts.
#        dato[:_preferred_name_italicized] = dato.hierarchy_entries.first.name[:italicized] unless dato.hierarchy_entries.first.nil?
#        if dato[:_preferred_name_italicized].nil? then
#          tc = tcs.first if tc.nil? # Grab the first unpublished taxon concept if we didn't find a published one earlier.
#          dato[:_preferred_name_italicized] = tc.nil? ? nil : tc.quick_scientific_name(:italicized)
#        end
#      end
#
#      dato[:_description_teaser] = ""
#      unless dato.description.blank? then
#        dato[:_description_teaser] = Sanitize.clean(dato.description, :elements => %w[b i],
#                                                    :remove_contents => %w[table script])
#        dato[:_description_teaser] = dato[:_description_teaser].split[0..80].join(' ').balance_tags +
#                                     '...' if dato[:_description_teaser].length > 500
#      end
#
#    end
#  end
#
#  def species_curated
#    page = (params[:page] || 1).to_i
#    current_user.log_activity(:show_species_curated_by_user_id, :value => params[:id])
#    @taxon_concept_ids = @user.taxon_concept_ids_curated.paginate(:page => page, :per_page => @@objects_per_page)
#  end
#
#  def comments_moderated
#    page = (params[:page] || 1).to_i
#    current_user.log_activity(:show_species_comments_moderated_by_user_id, :value => params[:id])
#    comment_curation_actions = @user.comment_curation_actions
#    @comment_curation_actions = comment_curation_actions.paginate(:page => page, :per_page => @@objects_per_page)
#  end

private

  def users_layout # choose an appropriate views layout for an action
    case action_name
    when 'forgot_password', 'terms_agreement', 'new', 'pending', 'activated'
      'v2/sessions'
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
    render :action => :new
  end

  def failed_to_update_user
    @user.clear_entered_password if @user
    flash.now[:error] = I18n.t(:update_user_unsuccessful_error)
    render :action => :edit
  end

  # Change password parameters when they are set automatically by an auto fill password management of a browser (known behavior of Firefox for example)
  def unset_auto_managed_password
    password = params[:user][:entered_password].strip
    if params[:user][:entered_password_confirmation].blank? && !password.blank? && User.hash_password(password) == User.find(current_user.id).hashed_password
      params[:user][:entered_password] = ''
    end
  end

  def send_verification_email
    Notifier.deliver_verify_user(@user, verify_user_url(@user.username, @user.validation_code))
  end

  def generate_api_key
    @user.clear_entered_password
    @user = alter_current_user do |user|
      user.update_attributes({ :api_key => User.generate_key })
    end
    render :action => :edit
  end

end
