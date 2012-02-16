class Users::NewsfeedsController < UsersController

  # GET /users/:user_id/newsfeed
  def show
    @parent = user # for new comment form
    @log = user.activity_log(:news => true, :page => params[:page] || 1)
    # reset last-seen dates:
    # QUESTION: if they see this all newsfeed, doesn't that mean they also see their new messages i.e. last_message_at should be updated too?
    # QUESTION: what if they only see page 1 of their latest notifications?
    user.update_attribute(:last_notification_at, Time.now) if user.id == current_user.id
    # Uses log results to calculate page numbering for rel link tags
    @rel_canonical_href = user_newsfeed_url(user, :page => rel_canonical_href_page_number(@log))
    @rel_prev_href = rel_prev_href_params(@log) ? user_newsfeed_url(@rel_prev_href_params) : nil
    @rel_next_href = rel_next_href_params(@log) ? user_newsfeed_url(@rel_next_href_params) : nil
  end

  # GET /users/:user_id/newsfeed/messages
  def messages
    @parent = user # for new comment form
    @log = user.messages(:page => params[:page] || 1)
    # reset last-seen dates:
    user.update_attribute(:last_message_at, Time.now) if user.id == current_user.id
    @rel_canonical_href = user_newsfeed_url(user)
    @rel_prev_href = rel_prev_href_params(@log) ? messages_user_newsfeed_url(@rel_prev_href_params) : nil
    @rel_next_href = rel_next_href_params(@log) ? messages_user_newsfeed_url(@rel_next_href_params) : nil
  end

  # GET /users/:user_id/newsfeed/activity
  def activity
    # TODO: activity is presumable newfeed minus messages
    @parent = user # for new comment form
    @log = []
    # uses log to figure out rel prev and next pages
    @rel_canonical_href = user_newsfeed_url(user)
    @rel_prev_href = rel_prev_href_params(@log) ? messages_user_newsfeed_url(@rel_prev_href_params) : nil
    @rel_next_href = rel_next_href_params(@log) ? messages_user_newsfeed_url(@rel_next_href_params) : nil
  end

protected
  def user
    @user ||= User.find(params[:user_id])
  end
  helper_method :user

end
