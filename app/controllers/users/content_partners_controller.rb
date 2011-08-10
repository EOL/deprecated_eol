class Users::ContentPartnersController < UsersController

  # GET /users/:user_id/content_partners
  def index
    @user = User.find(params[:user_id])
    # TODO: Will need to be modified when we move to many to many relationship between users and partners
    @partners = [@user.content_partner].compact
    @new_partner = ContentPartner.new
  end

end