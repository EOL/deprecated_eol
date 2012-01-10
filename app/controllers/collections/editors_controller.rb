class Collections::EditorsController < CollectionsController

  before_filter :set_filter_to_editors
  before_filter :find_collection
  before_filter :prepare_show
  before_filter :user_able_to_view_collection
  before_filter :find_parent

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
