class Mobile::ContentsController < Mobile::MobileController

  def index
    #rendering static example content for now
  end

  def enable
    session[:mobile_disabled] = false
    render :update do |page|
      page.redirect_to mobile_contents_path
    end
  end

  def disable
    session[:mobile_disabled] = true
    respond_to do |format|
      format.html {
        redirect_to root_path
      }
      format.js {
        render :update do |page|
          page.redirect_to root_path
        end
      }
    end
  end

end
