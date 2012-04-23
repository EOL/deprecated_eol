class Collections::InaturalistsController < CollectionsController

  skip_before_filter :user_able_to_edit_collection
  skip_before_filter :build_collection_items
  before_filter :set_filter_to_newsfeed

  layout 'v2/collections'

  def show
    @inaturalist_url_for_iframe = "#{@collection.inaturalist_url.strip}?iframe=true"
  end

private

  # This aids in the views and in the methods from the parent controller:
  def set_filter_to_newsfeed
    params[:filter] = 'inaturalist'
    @filter = 'inaturalist'
  end

end
