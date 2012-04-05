class Users::OpenAuthenticationsController < UsersController

  layout 'v2/users'

  skip_before_filter :redirect_if_already_logged_in

  # GET /users/:user_id/open_authentications
  def index
    @user = User.find(params[:user_id], :include => :open_authentications)
    raise EOL::Exceptions::SecurityViolation,
      "User with ID=#{current_user.id} does not have edit access to User with ID=#{@user.id}" unless current_user.can_update?(@user)
  end

  # GET /users/:user_id/open_authentications/new
  def new
    @user = User.find(params[:user_id])
    raise EOL::Exceptions::SecurityViolation,
      "User with ID=#{current_user.id} does not have permission to add open authentications for User with ID=#{@user.id}"
      unless current_user.can_update?(@user)
    redirect_to user_open_authentications_url(@user) unless params[:open_authentication]
    # We are about to call create method on a GET - not very secure, but we are restricting to admins and 
    # only allowing editing of self, is there more we can do?
    return create
  end

  # POST /users/:user_id/open_authentications
  def create
    oauth_provider = params[:open_authentication][:provider]
    if request.post?
      @user = User.find(params[:user_id])
      raise EOL::Exceptions::SecurityViolation,
        "User with ID=#{current_user.id} does not have permission to add open authentications for User with ID=#{@user.id}"
        unless current_user.can_update?(@user)
      open_auth = EOL::OpenAuth.init(oauth_provider, verify_open_authentication_users_url(:oauth_provider => oauth_provider))
      open_auth.prepare_for_authorization
      session.merge!(open_auth.session_data) if defined?(open_auth.request_token)
      session["#{oauth_provider}_authentication_eol_user_id"] = @user.id
      return redirect_to open_auth.authorize_uri
    elsif request.get?
      # We got here from new action
      guid = params[:open_authentication][:guid]
      params[:open_authentication][:token] = session.delete("oauth_token_#{oauth_provider}_#{guid}")
      params[:open_authentication][:secret] = session.delete("oauth_secret_#{oauth_provider}_#{guid}")
      open_authentication = @user.open_authentications.build(params[:open_authentication])
      if open_authentication.save
        flash[:notice] = I18n.t(:new_authentication_added, :scope => [:users, :open_authentications, :notices, oauth_provider.to_sym])
      else
        flash[:error] = I18n.t(:new_authentication_not_added, :scope => [:users, :open_authentications, :errors, oauth_provider.to_sym])
      end
    end
    redirect_to user_open_authentications_url(@user)
  end

  private

  def open_authentication_providers
    @open_authentication_providers ||= @user.open_authentications.collect{ |oa| oa.provider } if @user.open_authentications
  end
  helper_method :open_authentication_providers

end

