class Mobile::ContentsController < Mobile::MobileController

  def index
    @explore_taxa = RandomHierarchyImage.random_set(6)
  end

  def enable
    session[:mobile_disabled] = false
    respond_to do |format|
      format.html {
        redirect_to mobile_contents_path, :status => :moved_permanently
      }
      format.js {
        render :update do |page|
          page.redirect_to mobile_contents_path, :status => :moved_permanently
        end
      }
    end
  end

  def disable
    session[:mobile_disabled] = true
    respond_to do |format|
      format.html {
        redirect_to root_path, :status => :moved_permanently
      }
      format.js {
        render :update do |page|
          page.redirect_to root_path, :status => :moved_permanently
        end
      }
    end
  end

end
