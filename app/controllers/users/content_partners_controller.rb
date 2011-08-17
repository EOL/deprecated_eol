class Users::ContentPartnersController < UsersController

  # GET /users/:user_id/content_partners
  def index
    @user = User.find(params[:user_id], :include => [:content_partner])
    # TODO: Will need to be modified when we move to many to many relationship between users and partners
    @partners = [@user.content_partner].compact
    @new_partner = ContentPartner.new(:user => @user) if @partners.blank?
  end

end