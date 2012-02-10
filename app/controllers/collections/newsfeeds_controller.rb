class Collections::NewsfeedsController < CollectionsController

  skip_before_filter :user_able_to_edit_collection
  skip_before_filter :build_collection_items
  before_filter :set_filter_to_newsfeed

  layout 'v2/collections'

  def show
  end

private

  # This aids in the views and in the methods from the parent controller:
  def set_filter_to_newsfeed
    params[:filter] = 'newsfeed'
    @filter = 'newsfeed'
  end

end
