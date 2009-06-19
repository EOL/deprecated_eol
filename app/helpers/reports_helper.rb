module ReportsHelper
  
  def curator_or_plain_username(user)
    if user.is_curator?
        return(link_to(h("#{user.username}"), 
          :controller => "../account", :action => :show, 
          :id => user.id, :popup => true))   
    else
        return user.username
    end
  end
  
end