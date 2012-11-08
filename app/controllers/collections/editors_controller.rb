class Collections::EditorsController < CollectionsController

  skip_before_filter :user_able_to_edit_collection
  skip_before_filter :build_collection_items

  layout 'v2/collections'

  def index
    @rel_canonical_href = collection_editors_url(@collection)
    # This aids in the views and in the methods from the parent controller:
    @filter = params[:filter] = 'editors'
  end

end
