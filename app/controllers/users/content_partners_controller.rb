class Users::ContentPartnersController < UsersController

  # GET /users/:user_id/content_partners
  def index
    @user = User.find(params[:user_id], :include => [:content_partner])
    @partners = [@user.content_partner].compact if current_user.can_read?(@user.content_partner)
    @new_partner = ContentPartner.new(:user => @user)
    @new_partner = nil unless current_user.can_create?(@new_partner)
  end

end
