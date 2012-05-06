class Collections::InaturalistsController < CollectionsController

  skip_before_filter :user_able_to_edit_collection
  skip_before_filter :build_collection_items
  before_filter :set_filter_to_inaturalist

  layout 'v2/collections'

  def show
    @inaturalist_project_id = @collection.inaturalist_project_info['id']
    @inaturalist_project_title = @collection.inaturalist_project_info['title']
    @inaturalist_observed_taxa_count = @collection.inaturalist_project_info['observed_taxa_count']
    @inaturalist_project_observations = inaturalist_project_observations(@inaturalist_project_id)
  end

private

  # This aids in the views and in the methods from the parent controller:
  def set_filter_to_inaturalist
    params[:filter] = 'inaturalist'
    @filter = 'inaturalist'
  end

  def inaturalist_project_observations(project_id)
    url = "http://www.inaturalist.org/observations/project/#{project_id}.json?per_page=20"
    response = Net::HTTP.get(URI.parse(url))
    JSON.parse(response)
  end

end
