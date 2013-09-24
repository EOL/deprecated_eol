class Users::CollectionsController < UsersController

  skip_before_filter :extend_for_open_authentication

  # GET /users/:user_id/collections
  def index
    @user = User.find(params[:user_id])
    redirect_if_user_is_inactive
    preload_user_associations
    @published_collections = @user.published_collections(current_user)
    sort_by = params[:sort_by] && params[:sort_by].to_sym
    if sort_by == :oldest
      @published_collections = @published_collections.sort_by(&:created_at)
    elsif sort_by == :newest
      @published_collections = @published_collections.sort_by { |c| - c.created_at.to_i }
    end
    @rel_canonical_href = user_collections_url(@user)
  end

end
