# Handles non-admin curator functions, such as those performed by curators on individual species pages.
class CuratorsController < ApplicationController
  
  layout 'left_menu'

  access_control :DEFAULT => Role.curator.title
    
  before_filter :check_authentication
  before_filter :set_no_cache
  before_filter :set_layout_variables

  def index
  end
  
  def profile
    @user = User.find(current_user.id)
    @user.log_activity(:viewed_curator_profile)
    @user_submitted_text_count = UsersDataObject.count(:conditions=>['user_id = ?',params[:id]])
    redirect_back_or_default unless @user.curator_approved
  end
  
  
  def curate_images
    current_user.log_activity(:viewed_images_to_curator)
    @images_to_curate = current_user.images_to_curate
  end

private
  
  def set_no_cache
    @no_cache=true
  end      

  def set_layout_variables
    @page_title = $CURATOR_CENTRAL_TITLE
    @navigation_partial = '/curators/navigation'
  end

end
