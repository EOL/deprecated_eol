class Users::ActivitiesController < UsersController

  skip_before_filter :extend_for_open_authentication

  # GET /users/:user_id/activity
  def show
    @user = User.find(params[:user_id])
    redirect_if_user_is_inactive
    preload_user_associations
    @page = params[:page]
    @filter = params[:filter]
    if @filter == "curated_taxa"
      @curated_taxa_ids = Curator.taxon_concept_ids_curated(@user.id).paginate(page: @page, per_page: 20)
      # TODO: I think the use if the filter for curated taxa is weird since its not included in the filter list for the user
      # This also messes up SEO as filter all does not include this data.
      # TODO: we should provide unique meta data (title etc) for this filter's page
      set_canonical_urls(for: @user, paginated: @curated_taxa_ids, url_method: :user_activity_url)
    else
      @user_activity_log = @user.activity_log(page: @page, filter: @filter, user: current_user)
      set_canonical_urls(for: @user, paginated: @user_activity_log, url_method: :user_activity_url)
    end

  end

end
