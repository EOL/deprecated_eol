class Account::CollectionsController < AccountController

  layout 'v2/account'

  def show
    @user = current_user
    @collection_items = @user.collection_items
    @collections = (params[:sort_by].to_sym == :oldest) ?
      @user.collections.sort_by(&:created_at) : @user.collections.sort_by{|c| - c.created_at.to_i}
  end

end
