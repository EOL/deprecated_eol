class Users::NewsfeedsController < UsersController

  def show
    @user = User.find(params[:user_id])
    preload_user_associations
    @page = params[:page] || 1
    @parent = @user # for new comment form
    @user_activity_log = @user.activity_log(:news => true, :page => @page)
    @rel_canonical_href = user_newsfeed_url(@user, :page => rel_canonical_href_page_number(@user_activity_log))
    @rel_prev_href = rel_prev_href_params(@user_activity_log) ? user_newsfeed_url(@rel_prev_href_params) : nil
    @rel_next_href = rel_next_href_params(@user_activity_log) ? user_newsfeed_url(@rel_next_href_params) : nil
  end

end
