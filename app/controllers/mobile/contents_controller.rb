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
    render :update do |page|
      page.redirect_to root_path
    end
    #render :nothing => true
  end
  
end
