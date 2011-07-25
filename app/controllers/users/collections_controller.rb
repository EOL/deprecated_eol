class Users::CollectionsController < UsersController

  def index
    @user = User.find(params[:user_id])
    @collection_items = @user.collection_items
    @collections = (params[:sort_by] && params[:sort_by].to_sym == :oldest) ?
      @user.collections.sort_by(&:created_at) : @user.collections.sort_by{|c| - c.created_at.to_i}
  end

end
