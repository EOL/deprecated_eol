class Users::NotificationsController < UsersController

  layout 'v2/basic'

  # GET /users/:user_id/notification/edit
  def edit
    @user = User.find(params[:user_id])
    return access_denied unless current_user.can_update?(@user)
    instantiate_variables_for_notifications_settings
  end

  # PUT /users/:user_id/notification
  def update
    @user = User.find(params[:user_id])
    convert_notification_frequencies_ids_to_objects
    return access_denied unless current_user.can_update?(@user)
    if @user.update_attributes(params[:user])
      flash[:notice] = I18n.t(:notification_settings_successfully_updated, :scope => [:users, :notifications, :update])
      redirect_back_or_default edit_user_path(@user)
    else
      flash[:error] = I18n.t(:sorry_notification_settings_could_not_be_updated, :scope => [:users, :notifications, :update])
      instantiate_variables_for_notifications_settings
      render :edit
    end
  end

  private
  def instantiate_variables_for_notifications_settings
    @notification_frequencies = NotificationFrequency.all(:order => 'id DESC')
    @page_title = I18n.t(:page_title, :scope => [:users, :notifications, :edit])
    @page_description = I18n.t(:page_description, :scope => [:users, :notifications, :edit], :user_newsfeed_link => user_newsfeed_path(@user))
  end

  def convert_notification_frequencies_ids_to_objects
    new_params = {}
    params[:user][:notification_attributes].keys.each do |k|
      if k == 'id' || k == 'eol_newsletter'
        new_params[k] = params[:user][:notification_attributes][k].to_i
      else
        fqz = begin
                NotificationFrequency.find(params[:user][:notification_attributes][k].to_i)
              rescue ActiveRecord::RecordNotFound => e
                nil
              end
        new_params[k] = fqz if fqz
      end
    end
    params[:user][:notification_attributes] = new_params
  end

end
