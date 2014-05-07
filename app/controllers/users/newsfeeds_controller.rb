class Users::NewsfeedsController < UsersController

  skip_before_filter :extend_for_open_authentication
  before_filter :lookup_user
  before_filter :clear_session_partial

  # GET /users/:user_id/newsfeed
  def show
    redirect_if_user_is_inactive
    preload_user_associations
    @filter = params[:filter] || 'all'
    @filters = ['all', 'messages', 'community', 'collections', 'curation'] # TODO = 'watchlist' (can't do it now)
    respond_to do |format|
      format.html {
        conversion_code = session.delete(:conversion_code)
        if (params[:success] == conversion_code) && (conversion_code =~ /^[0-9a-f]{40}$/)
          @conversion = EOL::GoogleAdWords.create_signup_conversion
        end
        @page = params[:page] || 1
        @parent = @user # for new comment form
        @user_activity_log = @user.activity_log(news: true, page: @page, filter: @filter, user: current_user)
        # reset last-seen dates:
        # QUESTION: if they see this all newsfeed, doesn't that mean they also see their new messages i.e. last_message_at should be updated too?
        # QUESTION: what if they only see page 1 of their latest notifications?
        if @user.id == current_user.id
          @user.update_column(:last_notification_at, Time.now)
          @user.expire_primary_index
        end
        # Uses log results to calculate page numbering for rel link tags
        set_canonical_urls(for: @user, paginated: @user_activity_log, url_method: :user_newsfeed_url)
      }
      format.js do # link is called with AJAX to get pending count for session summary
        render text: I18n.t(:user_pending_notifications_with_count_assitive, count: @user.message_count)
      end
    end
  end

  # GET /users/:user_id/newsfeed/comments
  def comments
    respond_to do |format|
      format.html {
        @parent = @user # for new comment form
        @user_activity_log = @user.activity_log(news: true, filter: 'messages', page: params[:page] || 1, user: current_user)
        # reset last-seen dates:
        if @user.id == current_user.id
          @user.update_column(:last_message_at, Time.now)
          @user.expire_primary_index
        end
        set_canonical_urls(for: @user, paginated: @user_activity_log, url_method: :comments_user_newsfeed_url)
      }
      format.js do # link is called with AJAX to get pending count for session summary
        render text: I18n.t(:user_pending_notifications_comments_with_count_assistive, count: @user.message_count)
      end
    end
  end

protected
  def lookup_user
    @user = User.find(params[:user_id])
  end

end
