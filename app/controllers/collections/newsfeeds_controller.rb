class Collections::NewsfeedsController < CollectionsController

  skip_before_filter :user_able_to_edit_collection
  skip_before_filter :build_collection_items

  layout 'v2/collections'

  def show
    @activity_log = @collection.activity_log(:page => @page)
    @rel_canonical_href = collection_newsfeed_url(@collection, :page => rel_canonical_href_page_number(@activity_log))
    @rel_prev_href = rel_prev_href_params(@activity_log) ? collection_newsfeed_url(@rel_prev_href_params) : nil
    @rel_next_href = rel_next_href_params(@activity_log) ? collection_newsfeed_url(@rel_next_href_params) : nil
    # This aids in the views and in the methods from the parent controller:
    @filter = params[:filter] = 'newsfeed'
  end

end
