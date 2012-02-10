class Collections::EditorsController < CollectionsController

  skip_before_filter :user_able_to_edit_collection
  skip_before_filter :build_collection_items
  before_filter :set_filter_to_editors

  layout 'v2/collections'

  def show
  end

private

  # This aids in the views and in the methods from the parent controller:
  def set_filter_to_editors
    params[:filter] = 'editors'
    @filter = 'editors'
  end

end
