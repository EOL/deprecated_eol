class Users::CollectionsController < UsersController

  def index
    @user = User.find(params[:user_id])
    @featured_collections = (params[:sort_by] && params[:sort_by].to_sym == :oldest) ?
      @user.collections.sort_by(&:created_at) : @user.collections.sort_by{|c| - c.created_at.to_i}
    @featured_collections.delete_if{|c| c.id == @user.watch_collection.id}
  end

end
