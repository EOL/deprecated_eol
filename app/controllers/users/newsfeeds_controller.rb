class Users::NewsfeedsController < UsersController

  def show
    @user = User.find(params[:user_id])
    @parent = @user
  end

end
