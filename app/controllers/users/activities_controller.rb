class Users::ActivitiesController < UsersController

  def show
    @user = User.find(params[:user_id])
    @page = params[:page]
    @filter = params[:filter]
  end

end
