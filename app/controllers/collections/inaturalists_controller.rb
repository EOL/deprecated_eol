class Collections::InaturalistsController < CollectionsController

  skip_before_filter :user_able_to_edit_collection
  skip_before_filter :build_collection_items
  before_filter :set_filter_to_newsfeed

  layout 'v2/collections'

  def show
    # TODO: Figure out how to get iNaturalist Project name for this collection and assign it to @inaturalist_project_name
    @inaturalist_project_name = "this collection"
    @inaturalist_observations_url = @collection.inaturalist_observations_url
    @inaturalist_observations_widget_url = "#{@inaturalist_observations_url}.widget?layout=large&limit=20&order=desc&order_by=observed_on"
    @more_inaturalist_observations = I18n.t('helpers.label.collection.more_inaturalist_observations', :name => @inaturalist_project_name)
  end

private

  # This aids in the views and in the methods from the parent controller:
  def set_filter_to_newsfeed
    params[:filter] = 'inaturalist'
    @filter = 'inaturalist'
  end

end
