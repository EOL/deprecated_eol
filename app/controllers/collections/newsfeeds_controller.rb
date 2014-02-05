class Collections::NewsfeedsController < CollectionsController

  skip_before_filter :user_able_to_edit_collection
  skip_before_filter :build_collection_items

  layout 'collections'

  def show
    @activity_log = @collection.activity_log(page: @page, user: current_user)
    set_canonical_urls(for: @collection, paginated: @activity_log, url_method: :collection_newsfeed_url)
    # This aids in the views and in the methods from the parent controller:
    @filter = params[:filter] = 'newsfeed'
  end

end
