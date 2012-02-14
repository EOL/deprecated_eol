class Collections::NewsfeedsController < CollectionsController

  skip_before_filter :user_able_to_edit_collection
  skip_before_filter :build_collection_items
  before_filter :set_filter_to_newsfeed

  layout 'v2/collections'

  def show
    @rel_canonical_href = collection_newsfeed_url(@collection, :page => rel_canonical_href_page_number(@collection.activity_log))
    @rel_prev_href = rel_prev_href_params(@collection.activity_log) ? collection_newsfeed_url(@rel_prev_href_params) : nil
    @rel_next_href = rel_next_href_params(@collection.activity_log) ? collection_newsfeed_url(@rel_next_href_params) : nil
  end

private

  # This aids in the views and in the methods from the parent controller:
  def set_filter_to_newsfeed
    params[:filter] = 'newsfeed'
    @filter = 'newsfeed'
  end

end
