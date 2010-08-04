# Handles non-admin curator functions, such as those performed by curators on individual species pages.
class CuratorsController < ApplicationController
  
  layout 'curators'
  before_filter :check_authentication

  def index
  end
  
  def profile
    @user = User.find(current_user.id)
    @user_submitted_text_count = UsersDataObject.count(:conditions=>['user_id = ?',params[:id]])
    redirect_back_or_default unless @user.curator_approved
  end
  
  
  def curate_images
    @images_to_curate = current_user.images_to_curate
  end
  
end
