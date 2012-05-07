class Users::ContentPartnersController < UsersController

  skip_before_filter :extend_for_open_authentication

  # GET /users/:user_id/content_partners
  def index
    @user = User.find(params[:user_id], :include => [:content_partners])
    redirect_if_user_is_inactive
    preload_user_associations
    @partners = @user.content_partners
    @partners.delete_if{ |cp| !current_user.can_read?(cp) }
    @new_partner = ContentPartner.new(:user => @user)
    @new_partner = nil unless current_user.can_create?(@new_partner)
    @rel_canonical_href = user_content_partners_url(@user)
  end

end
