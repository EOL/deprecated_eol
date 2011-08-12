class Users::NewsfeedsController < UsersController

  def show
    @user = User.find(params[:user_id])
    @page = params[:page] || 1
    @parent = @user # for new comment form
  end

end
