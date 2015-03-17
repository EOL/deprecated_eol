class Users::CollectionsController < UsersController

  skip_before_filter :extend_for_open_authentication

  # GET /users/:user_id/collections
  def index
    @user = User.find(params[:user_id])
    redirect_if_user_is_inactive
    preload_user_associations
    @published_collections = @user.published_collections(current_user)
    sort_by = params[:sort_by] && params[:sort_by].to_sym
    @sorts = {
      I18n.t(:sort_by_alphabetical_option) => :alpha,
      I18n.t(:sort_by_reverse_alphabetical_option) => :rev,
      I18n.t(:sort_by_newest_option) => :newest,
      I18n.t(:sort_by_oldest_option) => :oldest
    }
    if sort_by == :rev
      @published_collections.reverse!
    elsif sort_by == :oldest
      @published_collections = @published_collections.sort_by { |c| c.created_at.to_i } # NOTE - to_i required; otherwise "comparison of NilClass"
    elsif sort_by == :newest
      @published_collections = @published_collections.sort_by { |c| - c.created_at.to_i }
    end
    @rel_canonical_href = user_collections_url(@user)
    respond_to do |format|
      format.html {}
      format.json do
        render(
          json: @published_collections.as_json()
        )
      end
    end
  end

end
