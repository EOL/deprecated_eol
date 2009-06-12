module ReportsHelper
  
  def curator_or_plain_username(user)
    if act_history.act_user.is_curator?
        return(link_to(h("#{act_history.act_user.username}"), 
          :controller => "../account", :action => :show, 
          :id => act_history.act_user.id, :popup => true))   
    else
        return act_history.act_user.username
    end
  end
  
end