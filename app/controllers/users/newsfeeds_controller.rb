class Users::NewsfeedsController < UsersController

  # GET /users/:user_id/newsfeed
  def show
    @user = user
    redirect_if_user_is_inactive
    preload_user_associations
    @filter = params[:filter] || 'all'
    @filters = ['all', 'messages', 'community', 'collections', 'watchlist', 'curation']
    respond_to do |format|
      format.html {
        @page = params[:page] || 1
        @parent = @user # for new comment form
        @user_activity_log = @user.activity_log(:news => true, :page => @page, :filter => @filter)
        # reset last-seen dates:
        # QUESTION: if they see this all newsfeed, doesn't that mean they also see their new messages i.e. last_message_at should be updated too?
        # QUESTION: what if they only see page 1 of their latest notifications?
        user.update_attribute(:last_notification_at, Time.now) if user.id == current_user.id
        # Uses log results to calculate page numbering for rel link tags
        @rel_canonical_href = user_newsfeed_url(@user, :page => rel_canonical_href_page_number(@user_activity_log))
        @rel_prev_href = rel_prev_href_params(@user_activity_log) ? user_newsfeed_url(@rel_prev_href_params) : nil
        @rel_next_href = rel_next_href_params(@user_activity_log) ? user_newsfeed_url(@rel_next_href_params) : nil
      }
      format.js do # link is called with AJAX to get pending count for session summary
        render :text => I18n.t(:user_pending_notifications_with_count_assitive, :count => user.message_count)
      end
    end
  end

  # GET /users/:user_id/newsfeed/comments
  def comments
    respond_to do |format|
      format.html {
        @parent = user # for new comment form
        @user_activity_log = user.messages(:page => params[:page] || 1)
        # reset last-seen dates:
        user.update_attribute(:last_message_at, Time.now) if user.id == current_user.id
        @rel_canonical_href = user_newsfeed_url(user)
        @rel_prev_href = rel_prev_href_params(@user_activity_log) ? comments_user_newsfeed_url(@rel_prev_href_params) : nil
        @rel_next_href = rel_next_href_params(@user_activity_log) ? comments_user_newsfeed_url(@rel_next_href_params) : nil
      }
      format.js do # link is called with AJAX to get pending count for session summary
        render :text => I18n.t(:user_pending_notifications_comments_with_count_assistive, :count => user.message_count)
      end
    end
  end

protected
  def user
    @user ||= User.find(params[:user_id])
  end
  helper_method :user

end
