class SessionsController < ApplicationController

  layout 'v2/sessions'

  before_filter :redirect_if_already_logged_in, :only => [:new, :create]
  before_filter :check_user_agreed_with_terms, :except => [:destroy]

  # GET /sessions/new or named route /login
  def new
    if params[:oauth_provider]
      if open_auth = EOL::OpenAuth.init(params[:oauth_provider], new_user_url(:oauth_provider => params[:oauth_provider]), params.merge({:request_token_token => session.delete("#{params[:oauth_provider]}_request_token_token"), :request_token_secret => session.delete("#{params[:oauth_provider]}_request_token_secret")}))
        
        if open_auth.user_attributes.nil? || open_auth.authentication_attributes.nil?
          flash.now[:error] = I18n.t(:oauth_error_accessing_basic_info)
        else
          if (authorized = OpenAuthentication.find_by_provider_and_guid(open_auth.authentication_attributes[:provider], open_auth.authentication_attributes[:guid], :include => :user)) && ! authorized.user.nil?
            # TODO: what do we do when we have authentication record but no user here?
            log_in(authorized.user)
            return redirect_to user_newsfeed_path(authorized.user)
          else
            # TODO: User not authorized - they might need to sign up or there is a problem
            # session["oauth_token_#{open_auth.authentication_attributes[:provider]}_#{open_auth.authentication_attributes[:guid]}"] = open_auth.authentication_attributes[:token]
            #             session["oauth_secret_#{open_auth.authentication_attributes[:provider]}_#{open_auth.authentication_attributes[:guid]}"] = open_auth.authentication_attributes[:secret]
            #             oauth_user_attributes = open_auth.user_attributes.merge({ :open_authentications_attributes => [
            #               { :guid => open_auth.authentication_attributes[:guid],
            #                 :provider => open_auth.authentication_attributes[:provider] }]})
          end
        end
      else
        flash.now[:error] = I18n.t(:oauth_error_initializing_access)
      end
    end
    @rel_canonical_href = login_url
  end

  # POST /sessions
  def create
    if params[:oauth_provider]
      if open_auth = EOL::OpenAuth.init(params[:oauth_provider], new_session_url(:oauth_provider => params[:oauth_provider]))
        session.merge!(open_auth.session_data) if defined?(open_auth.request_token)
        return redirect_to open_auth.authorize_uri
      else
        flash[:error] = I18n.t(:oauth_error_initializing_authorization, :oauth_provider => params[:oauth_provider])
        params.delete(:oauth_provider)
        return redirect_to :action => :new
      end
    end
    
    success, user = User.authenticate(params[:session][:username_or_email], params[:session][:password])
    if success && user.is_a?(User) # authentication successful
      if user.is_hidden?
        flash[:error] = I18n.t(:login_hidden_user_message, :given_name => user.given_name)
        redirect_to root_url(:protocol => "http"), :status => :moved_permanently
      else
        log_in user
        unless params[:session][:return_to].blank? || params[:session][:return_to] == root_url
          store_location(params[:session][:return_to])
        end
        redirect_back_or_default(user_newsfeed_path(current_user))
      end
    else # authentication unsuccessful
      if user.blank? && User.active_on_master?(params[:session][:username_or_email])
        flash[:notice] = I18n.t(:account_registered_but_not_ready_try_later)
      else
        flash[:error] = I18n.t(:sign_in_unsuccessful_error)
        redirect_to login_path
      end
    end
  end

  # DELETE /sessions/:id or named route /logout
  def destroy
    log_out
    store_location(params[:return_to])
    flash[:notice] = I18n.t(:you_have_been_logged_out)
    redirect_back_or_default
  end

private

  def log_out
    cookies.delete :user_auth_token
    session[:language] = current_user.language_abbr # Store this, so it doesn't change on logout.
    reset_session
  end
end
