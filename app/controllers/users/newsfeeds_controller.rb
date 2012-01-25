class Users::NewsfeedsController < UsersController

  def show
    @user = User.find(params[:user_id])
    @page = params[:page] || 1
    @parent = @user # for new comment form
    @filter = params[:filter]
    # reset last-seen dates:
    if @user.id == current_user.id
      if @filter == 'messages'
        @user.update_attribute(:last_message_at, Time.now)
      else
        @user.update_attribute(:last_notification_at, Time.now)
      end
    end
  end

end
