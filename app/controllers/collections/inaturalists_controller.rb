class Collections::InaturalistsController < CollectionsController

  skip_before_filter :user_able_to_edit_collection
  skip_before_filter :build_collection_items
  before_filter :set_filter_to_inaturalist

  layout 'v2/collections'

  def show
    @inaturalist_project_id = @collection.inaturalist_project_details['id']
    @inaturalist_project_title = @collection.inaturalist_project_details['title']
    @inaturalist_observed_taxa_count = @collection.inaturalist_project_details['observed_taxa_count']
  end

private

  # This aids in the views and in the methods from the parent controller:
  def set_filter_to_inaturalist
    params[:filter] = 'inaturalist'
    @filter = 'inaturalist'
  end

end
