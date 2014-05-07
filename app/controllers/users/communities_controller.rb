class Users::CommunitiesController < UsersController

  skip_before_filter :extend_for_open_authentication

  # GET /users/:user_id/communities
  def index
    @user = User.find(params[:user_id], include: { members: :community })
    redirect_if_user_is_inactive
    preload_user_associations
    if params[:sort_by] == 'newest' || params[:sort_by].nil?
      @communities = @user.communities.published.sort! { |a,b| b.created_at <=> a.created_at }
    else
      @communities = @user.communities.published.sort! { |a,b| a.created_at <=> b.created_at }
    end
    @rel_canonical_href = user_communities_url(@user)
  end

end
