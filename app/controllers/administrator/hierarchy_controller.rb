class Administrator::HierarchyController < AdminController
  helper :resources
  helper_method :current_agent, :agent_logged_in?
  layout 'admin'
  
  access_control :DEFAULT => 'Administrator - Content Partners'
  
  def index
    page=params[:page] || '1'
    @page_title = 'Hierarchies'
    @hierarchies = Hierarchy.paginate_by_sql("SELECT h.*, a.full_name agent_name FROM hierarchies h LEFT JOIN agents a ON (h.agent_id=a.id)", :page=>page)
  end
  
  def browse
    @hierarchy = Hierarchy.find_by_id(params[:id])
    if @hierarchy.blank?
      redirect_to :action=>'index' 
      return
    end
  end
  
  def edit
    @hierarchy = Hierarchy.find_by_id(params[:id])
    if @hierarchy.blank?
      redirect_to :action=>'index' 
      return
    end
    if request.post?
      if @hierarchy.update_attributes(params[:hierarchy])
        flash[:notice] = "Hierarchy updated"
        redirect_to :action => 'browse', :id => @hierarchy.id 
      end
    end
  end
end
