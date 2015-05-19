class Users::OpenAuthenticationsController < UsersController

  layout 'basic'

  skip_before_filter :redirect_if_already_logged_in
  skip_before_filter :extend_for_open_authentication

  # GET /users/:user_id/open_authentications
  def index
    @user = User.find(params[:user_id], include: :open_authentications)
    
    raise EOL::Exceptions::SecurityViolation.new("User with ID=#{current_user.id} does not have permission to view open authentications"\
      " for User with ID=#{@user.id}", :missing_permission_to_view_open_authentications) unless current_user.can_update?(@user)

    # Clean up session from previous incomplete authorizations, e.g. when users use browser back button
    session.delete_if{|k,v| k.to_s.match /^[a-z]+(?:_request_token_(?:token|secret)|_oauth_state)$/i}
  end

  # GET /users/:user_id/open_authentications/new
  # Does not have a View no render, just used behind the scenes.
  def new
    unless oauth_provider = params[:oauth_provider]
      redirect_to user_open_authentications_url(params[:user_id]) and return
    end

    @user = User.find(params[:user_id])
    
    raise EOL::Exceptions::SecurityViolation.new("User with ID=#{current_user.id} does not have permission to add open authentications"\
      " for User with ID=#{@user.id}", :missing_permission_to_add_open_authentications) unless current_user.can_update?(@user)

    @open_auth = EOL::OpenAuth.init(oauth_provider,
                      verify_open_authentication_users_url(oauth_provider: oauth_provider),
                      params.merge({stored_state: session.delete("#{oauth_provider}_state"),
                          request_token_token: session.delete("#{oauth_provider}_request_token_token"),
                          request_token_secret: session.delete("#{oauth_provider}_request_token_secret")}))

    # TODO: Bit risky here? Potential for a redirect loop if something breaks
    if @open_auth.access_denied?
      # Note: Access denied doesn't apply to Yahoo! they don't have a cancel button.
      raise EOL::Exceptions::OpenAuthUnauthorized,
        "User with id=#{current_user.id} denied access to add connection with #{@open_auth.provider}."
    elsif @open_auth.authorized?
      if @open_auth.have_attributes?
        if @open_auth.is_connected?
          if @open_auth.open_authentication.user_id == current_user.id
            @open_auth.open_authentication.connection_established
          else
            flash[:error] = I18n.t(:add_connection_failed_account_already_connected,
                                   existing_eol_account_url: user_url(@open_auth.open_authentication.user_id),
                                   scope: [:users, :open_authentications, :errors, @open_auth.provider])
          end
        else
          create and return
        end
      else
        flash[:error] = I18n.t(:missing_attributes, scope: [:users, :open_authentications,
                                                               :errors, @open_auth.provider])
      end
    else
      session.merge!(@open_auth.session_data)
      redirect_to @open_auth.authorize_uri and return
    end
    # Something weird happened if we get here
    redirect_to user_open_authentications_url(@user)
  end

  # No route at the moment since we're calling it directly from the new action.
  def create
    if request.get? && params[:action] == 'new'
      open_authentication = @user.open_authentications.build(@open_auth.authentication_attributes.merge(verified_at: Time.now))
      if open_authentication.save
        flash[:notice] = I18n.t(:new_authentication_added,
                                scope: [:users, :open_authentications, :notices, @open_auth.provider.to_sym])
      else
        flash[:error] = I18n.t(:new_authentication_not_added,
                               scope: [:users, :open_authentications, :errors, @open_auth.provider.to_sym])
      end
    end
    redirect_to user_open_authentications_url(@user)
  end

  def update
    # TODO: verify a connected account - check we have access to basic info.
  end

  def destroy
    @user = User.find(params[:user_id], include: :open_authentications)
    open_authentication = OpenAuthentication.find(params[:id])
    
    raise EOL::Exceptions::SecurityViolation("User with ID=#{current_user.id} does not have"\
      " permission to remove OpenAuthentication with ID=#{open_authentication.id} connected to"\
      " User with ID=#{@user.id}", :missing_permission_to_delete_open_authentications) unless current_user.can_delete?(open_authentication)
    if @user.open_authentications.delete(open_authentication)
      if @user.open_authentications.blank? && @user.hashed_password.blank?
        flash.now[:warning] = I18n.t(:no_way_to_login,
                                     scope: [:users, :open_authentications, :warnings])
      end
      flash.now[:notice] = I18n.t(:removed_connection,
                                  scope: [:users, :open_authentications, :notices,
                                             open_authentication.provider.to_sym])
    else
      flash.now[:error] = I18n.t(:remove_connection_failed,
                                 scope: [:users, :open_authentications, :errors])
    end
    page_title([:users, :open_authentications, :index])
    page_description([:users, :open_authentications, :index])
    render :index
  end

end

