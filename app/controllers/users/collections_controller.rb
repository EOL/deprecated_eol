class Users::CollectionsController < UsersController

  def index
    @user = User.find(params[:user_id])
    preload_user_associations
    @featured_collections = @user.all_collections(@user)
    if params[:sort_by] && params[:sort_by].to_sym == :oldest
      @featured_collections = @featured_collections.sort_by(&:created_at)
    else
      @featured_collections = @featured_collections.sort_by{|c| - c.created_at.to_i}
    end
    @featured_collections.delete_if{|c| c.id == @user.watch_collection.id}
    @rel_canonical_href = user_collections_url(@user)
  end

end
