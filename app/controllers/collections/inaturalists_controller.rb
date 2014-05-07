class Collections::InaturalistsController < CollectionsController

  skip_before_filter :user_able_to_edit_collection
  skip_before_filter :build_collection_items

  layout 'collections'

  def show
    @inaturalist_project_id = @collection.inaturalist_project_info['id']
    @inaturalist_project_title = @collection.inaturalist_project_info['title']
    @inaturalist_observed_taxa_count = @collection.inaturalist_project_info['observed_taxa_count']
    if @inaturalist_project_id
      @inaturalist_project_observations = inaturalist_project_observations(@inaturalist_project_id)
    end
    # This aids in the views and in the methods from the parent controller:
    @filter = params[:filter] = 'inaturalist'
    if logged_in? && (authentications = current_user.open_authentications)
      @embed_auth_provider = "auth_provider=#{authentications.first.provider}" unless authentications.blank?
    end
  end

private

  def inaturalist_project_observations(project_id)
    return nil if project_id.nil?
    return nil if project_id == "[DATA MISSING]" # TODO - lame. We should have a way to express this.  :|
    url = "http://www.inaturalist.org/observations/project/#{project_id}.json?per_page=20"
    response = Net::HTTP.get(URI.parse(url))
    JSON.parse(response)
  end

end
