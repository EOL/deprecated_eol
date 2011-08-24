class Users::CommunitiesController < UsersController

  def index
    @user = User.find(params[:user_id], :include => { :members => :community })
  end
end