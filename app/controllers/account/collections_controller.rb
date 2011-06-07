class Account::CollectionsController < AccountController

  layout 'v2/account'

  def show
    @user = current_user
    @collection_items = @user.collection_items
    @collections = @user.collections
  end

end
