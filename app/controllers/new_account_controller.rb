class NewAccountController < ApplicationController
  before_filter :check_authentication
  layout :main_if_not_logged_in
  
  def profile
    @page_header = I18n.t("account_settings")
    @user = User.find(current_user.id)
    if params[:user]
      unset_auto_managed_password
      if params[:user][:entered_password] && params[:user][:entered_password_confirmation]
        if !password_length_okay?
          flash[:error] = I18n.t(:password_must_be_4to16_characters)
          return
        elsif params[:user][:entered_password] != params[:user][:entered_password_confirmation]
          flash[:error] = I18n.t(:passwords_must_match)
          return
        end
        current_user.password = params[:user][:entered_password]
      end
      current_user.log_activity(:updated_profile)
      alter_current_user do |user|
        user.update_attributes(params[:user])
      end
      flash[:notice] =  I18n.t(:your_preferences_have_been_updated)
    end
    @user = User.find(current_user.id)
  end
  
  def personal_profile
    @page_header = I18n.t("personal_profile_menu")
    if params[:user]
      current_user.log_activity(:updated_profile)
      alter_current_user do |user|
        user.update_attributes(params[:user])
      end
      flash[:notice] =  I18n.t(:your_preferences_have_been_updated)
    end
    @user = User.find(current_user.id)
  end
  
  def site_settings
    @page_header = I18n.t("site_settings_menu")
    if params[:user]
      current_user.log_activity(:updated_profile)
      alter_current_user do |user|
        user.update_attributes(params[:user])
      end
      flash[:notice] =  I18n.t(:your_preferences_have_been_updated)
    end
    @user = User.find(current_user.id)
  end

private
  def main_if_not_logged_in
    layout = current_user.nil? ? 'main' : 'user_profile'
  end
  
  def password_length_okay?
    return !(params[:user][:entered_password].length < 4 || params[:user][:entered_password].length > 16)
  end
  
  # Change password parameters when they are set automatically by an autofil password management of a browser (known behavior of Firefox for example)
  def unset_auto_managed_password
    password = params[:user][:entered_password].strip
    if params[:user][:entered_password_confirmation].blank? && !password.blank? && User.hash_password(password) == User.find(current_user.id).hashed_password
      params[:user][:entered_password] = ''
    end
  end
end
