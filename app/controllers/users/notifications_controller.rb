class Users::NotificationsController < UsersController

  before_filter :authentication_only_allow_editing_of_self, :only => [:edit, :update]

  layout 'v2/basic'

  # GET /users/:user_id/notification/edit
  def edit
    # @user instantiated by authentication before filter and matched to current user
    instantiate_variables_for_notifications_settings
  end

  # PUT /users/:user_id/notification
  def update
    # @user instantiated by authentication before filter and matched to current user
    if @user.update_attributes(params[:user])
      flash[:notice] = "Notification settings successfully updated."
      redirect_back_or_default edit_user_path(@user)
    else
      flash[:error] = "Sorry, notification settings could not be updated."
      instantiate_variables_for_notifications_settings
      render :edit
    end
  end
  
  private
  def instantiate_variables_for_notifications_settings
    # @user instantiated by authentication before filter and matched to current user
    @notification_frequencies = NotificationFrequency.all(:order => 'id DESC')
    @page_title = I18n.t(:page_title, :scope => [:users, :notifications, :edit])
    @page_description = I18n.t(:page_description, :scope => [:users, :notifications, :edit], :user_newsfeed_link => user_newsfeed_path(@user))
  end
end
