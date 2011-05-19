class CuratorAccountController < ApplicationController
  before_filter :check_authentication
  layout 'user_profile'
  
  def profile
    @page_header = I18n.t("curator_profile_menu")
    if params[:user]
      # The UI would not allow this, but a hacker might try to grant curator permissions to themselves in this manner.
      params[:user].delete(:curator_approved) unless is_user_admin?
      
      current_user.log_activity(:updated_profile)
      @user = alter_current_user do |user|
        user.update_attributes(params[:user])
      end
      flash[:notice] =  I18n.t(:your_preferences_have_been_updated)
    end
  end
end
