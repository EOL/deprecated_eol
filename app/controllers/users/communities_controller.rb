class Users::CommunitiesController < UsersController

  def index
    @user = User.find(params[:user_id], :include => { :members => :community })
    if params[:sort_by] == 'newest' || params[:sort_by].nil?
      @communities = @user.communities.published.sort! { |a,b| b.created_at <=> a.created_at }
    else
      @communities = @user.communities.published.sort! { |a,b| a.created_at <=> b.created_at }
    end
    @rel_canonical_href = user_communities_url(@user)
  end

end