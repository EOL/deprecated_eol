class Users::OpenAuthenticationsController < UsersController

  layout 'v2/basic'

  skip_before_filter :redirect_if_already_logged_in
  skip_before_filter :extend_for_open_authentication

  # GET /users/:user_id/open_authentications
  def index
    @user = User.find(params[:user_id], :include => :open_authentications)
    raise EOL::Exceptions::SecurityViolation,
      "User with ID=#{current_user.id} does not have permission to view open authentications"\
      " for User with ID=#{@user.id}" unless current_user.can_update?(@user)
    @page_title = I18n.t(:page_title, :scope => controller_action_scope)
    @page_description = I18n.t(:page_description, :scope => controller_action_scope)
  end

  # GET /users/:user_id/open_authentications/new
  # Does not have a View no render, just used for behind the scene redirects
  def new
    redirect_to edit_user_url(params[:user_id]) unless params[:open_authentication] || params[:oauth_provider]
    @user = User.find(params[:user_id])
    raise EOL::Exceptions::SecurityViolation,
      "User with ID=#{current_user.id} does not have permission to add open authentications"\
      " for User with ID=#{@user.id}" unless current_user.can_update?(@user)
    if oauth_provider = params.delete(:oauth_provider) # new connection, get authorization
      open_auth = EOL::OpenAuth.init(oauth_provider, verify_open_authentication_users_url(:oauth_provider => oauth_provider))
      open_auth.prepare_for_authorization
      session.merge!(open_auth.session_data) if defined?(open_auth.request_token)
      return redirect_to open_auth.authorize_uri
    else # authorization granted, add connection
      # We are about to call create method on a GET - not very secure, but we are restricting to admins and 
      # only allowing editing of self, is there more we can do?
      return create
    end
  end

  # POST /users/:user_id/open_authentications
  def create
    oauth_provider = params[:open_authentication][:provider]

    if request.post? && params[:action] == 'create' # action could be also be :new
      @user = User.find(params[:user_id])
      raise EOL::Exceptions::SecurityViolation,
        "User with ID=#{current_user.id} does not have permission to add open authentications"\
        " for User with ID=#{@user.id}" unless current_user.can_update?(@user)
      @open_auth = EOL::OpenAuth.init(oauth_provider, 
                                      verify_open_authentication_users_url(:oauth_provider => oauth_provider))
      @open_auth.prepare_for_authorization
      session.merge!(@open_auth.session_data) if defined?(@open_auth.request_token)
      redirect_to @open_auth.authorize_uri and return

    elsif request.get? && params[:action] == 'new'
      # We came straight here from #new action so @user is already loaded
      guid = params[:open_authentication][:guid]
      params[:open_authentication][:token] = session.delete("oauth_token_#{oauth_provider}_#{guid}")
      params[:open_authentication][:secret] = session.delete("oauth_secret_#{oauth_provider}_#{guid}")
      params[:open_authentication][:verified_at] = Time.now
      open_authentication = @user.open_authentications.build(params[:open_authentication])
      if open_authentication.save
        flash[:notice] = I18n.t(:new_authentication_added,
                                :scope => [:users, :open_authentications, :notices, oauth_provider.to_sym])
      else
        flash[:error] = I18n.t(:new_authentication_not_added,
                               :scope => [:users, :open_authentications, :errors, oauth_provider.to_sym])
      end
    end
    redirect_to user_open_authentications_url(@user)
  end

  def destroy
    @user = User.find(params[:user_id], :include => :open_authentications)
    open_authentication = OpenAuthentication.find(params[:id])
    raise EOL::Exceptions::SecurityViolation,
         "User with ID=#{current_user.id} does not have permission to remove OpenAuthentication"\
         " with ID=#{open_authentication.id} connected to User with ID=#{@user.id}" unless current_user.can_delete?(open_authentication)
    if @user.open_authentications.delete(open_authentication)
      flash.now[:warning] = "You no longer have any connected accounts, you will not be able to log back into EOL unless you add a connected account or add an EOL username and password." if @user.open_authentications.blank? && @user.hashed_password.blank?
      flash.now[:notice] = "Successfully removed connection. EOL will still be authorized to access your info until you deauthorize the EOL app in your provider."
    else
      flash.now[:error] = "Unable to remove connection."
    end
    render :index
  end

end

