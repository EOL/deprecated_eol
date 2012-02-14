class SessionsController < ApplicationController

  layout 'v2/sessions'

  before_filter :redirect_if_already_logged_in, :only => [:new, :create]
  before_filter :check_user_agreed_with_terms, :except => [:destroy]

  # GET /sessions/new or named route /login
  def new
    @rel_canonical_href = login_url
  end

  # POST /sessions
  def create
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

  def log_in(user)
    set_current_user(user)
    flash[:notice] = I18n.t(:sign_in_successful_notice)
    if EOLConvert.to_boolean(params[:remember_me])
      if user.is_admin?
        flash[:notice] += " #{I18n.t(:sign_in_remember_me_disallowed_for_admins_notice)}"
      else
        user.remember_me
        cookies[:user_auth_token] = { :value => user.remember_token , :expires => user.remember_token_expires_at }
      end
    end
    session.delete(:recently_visited_collections)
    expire_user_specific_caches
  end

  def expire_user_specific_caches
    # the portion of the homepage underneath the march of life. Language-specific
    # expire_fragment(:controller => 'content', :part => 'home_' + current_user.content_page_cache_str + '_logged_in')
  end

  def log_out
    cookies.delete :user_auth_token
    session[:language] = current_user.language_abbr # Store this, so it doesn't change on logout.
    reset_session
  end
end
