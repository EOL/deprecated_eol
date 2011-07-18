class SessionsController < ApplicationController

  layout 'v2/sessions'

  before_filter :redirect_if_already_logged_in, :only => [:new, :create]
  before_filter :check_user_agreed_with_terms, :except => [:destroy]

  # GET /sessions/new or named route /login
  def new
  end

  # POST /sessions
  def create
    success, user = User.authenticate(params[:session][:username_or_email], params[:session][:password])

    if success && user.is_a?(User) # authentication successful
      log_in user
      store_location(params[:return_to]) unless params[:return_to].blank?
      redirect_back_or_default(current_user)
    else # authentication unsuccessful
      if user.blank? && User.active_on_master?(params[:session][:username_or_email])
        flash[:notice] = I18n.t(:account_registered_but_not_ready_try_later)
      else
        flash[:error] = I18n.t(:sign_in_unsuccessful_error)
      end
      redirect_to login_path

    end
  end

  # DELETE /sessions/:id or named route /logout
  def destroy
    log_out
    store_location(params[:return_to])
    flash[:notice] =  I18n.t(:you_have_been_logged_out)
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
  end

  def log_out
    cookies.delete :user_auth_token
    reset_session
  end
end
