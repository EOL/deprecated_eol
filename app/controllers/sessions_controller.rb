class SessionsController < ApplicationController

  include EOL::Login

  layout 'v2/sessions'

  before_filter :redirect_if_already_logged_in, :only => [:new, :create]
  before_filter :check_user_agreed_with_terms, :except => [:destroy]

  # GET /sessions/new or named route /login
  def new
    if params[:oauth_provider] && (open_auth = verify_open_authentication(new_session_url(:oauth_provider => params[:oauth_provider])))
      if (open_authentication = login_existing_open_authentication_user(open_auth))
        return redirect_to user_newsfeed_path(open_authentication.user)
      else
        # TODO: User not authorized - they might need to sign up or there is a problem
        # session["oauth_token_#{open_auth.authentication_attributes[:provider]}_#{open_auth.authentication_attributes[:guid]}"] = open_auth.authentication_attributes[:token]
        #             session["oauth_secret_#{open_auth.authentication_attributes[:provider]}_#{open_auth.authentication_attributes[:guid]}"] = open_auth.authentication_attributes[:secret]
        #             oauth_user_attributes = open_auth.user_attributes.merge({ :open_authentications_attributes => [
        #               { :guid => open_auth.authentication_attributes[:guid],
        #                 :provider => open_auth.authentication_attributes[:provider] }]})
      end
    end
    @rel_canonical_href = login_url
  end

  # POST /sessions
  def create
    return initialize_open_authentication(new_session_url(:oauth_provider => params[:oauth_provider]), 
                                          new_session_url) if params[:oauth_provider]
    
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
    lang = current_language.id
    reset_session
    session[:language_id] = lang # Don't want this to change on logout.
  end

end
