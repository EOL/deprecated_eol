class Users::CollectionsController < UsersController

  def index
    @user = User.find(params[:user_id])
    @featured_collections = (@user == current_user) ? @user.collections : @user.published_collections
    if params[:sort_by] && params[:sort_by].to_sym == :oldest
      @featured_collections = @featured_collections.sort_by(&:created_at)
    else
      @featured_collections = @featured_collections.sort_by{|c| - c.created_at.to_i}
    end
    @featured_collections.delete_if{|c| c.id == @user.watch_collection.id}
  end

end
