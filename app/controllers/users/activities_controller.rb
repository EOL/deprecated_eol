class Users::ActivitiesController < UsersController

  # GET /users/:user_id/activity
  def show
    @user = User.find(params[:user_id])
    redirect_if_user_is_inactive
    preload_user_associations
    @page = params[:page]
    @filter = params[:filter]
    if @filter == "curated_taxa"
      @curated_taxa_ids = User.taxon_concept_ids_curated(@user.id).paginate(:page => @page, :per_page => 20)
      # TODO: I think the use if the filter for curated taxa is weird since its not included in the filter list for the user
      # This also messes up SEO as filter all does not include this data.
      # TODO: we should provide unique meta data (title etc) for this filter's page
      @rel_canonical_href = user_activity_url(@user, :page => rel_canonical_href_page_number(@curated_taxa_ids), :filter => "curated_taxa")
      @rel_prev_href = rel_prev_href_params(@curated_taxa_ids) ? user_activity_url(@rel_prev_href_params) : nil
      @rel_next_href = rel_next_href_params(@curated_taxa_ids) ? user_activity_url(@rel_next_href_params) : nil
    else
      @user_activity_log = @user.activity_log(:page => @page, :filter => @filter)
      @rel_canonical_href = user_activity_url(@user, :page => rel_canonical_href_page_number(@user_activity_log))
      @rel_prev_href = rel_prev_href_params(@user_activity_log) ? user_activity_url(@rel_prev_href_params) : nil
      @rel_next_href = rel_next_href_params(@user_activity_log) ? user_activity_url(@rel_next_href_params) : nil
    end

  end

end
