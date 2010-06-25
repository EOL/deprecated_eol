class Administrator::HierarchyController < AdminController
  helper :resources
  helper_method :current_agent, :agent_logged_in?
  layout 'admin'
  
  access_control :DEFAULT => 'Administrator - Content Partners'
  
  def index
    page = params[:page] || '1'
    order = params[:order_by] || 'agent'
    case order
      when 'label'
        order_by = 'CONCAT_WS(" ", h.descriptive_label, h.label), h.id'
      when 'browsable'
        order_by = 'h.request_publish DESC, h.browsable DESC, a.full_name, h.id'
      else
        order_by = 'a.full_name, h.id'
    end
    @page_title = 'Hierarchies'
    @hierarchies = Hierarchy.paginate_by_sql("SELECT h.*, a.full_name agent_name, cp.agent_id content_partner_agent_id FROM hierarchies h LEFT JOIN agents a ON (h.agent_id=a.id) LEFT JOIN content_partners cp ON (a.id=cp.agent_id) ORDER BY #{order_by}", :page=>page)
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
      if params[:hierarchy][:browsable] == "1"
        params[:hierarchy][:request_publish] = false
      end
      if @hierarchy.update_attributes(params[:hierarchy])
        # if there were changes to what was browsable we want those changes immediately visible
        Rails.cache.delete('hierarchies/browsable_by_label')
        flash[:notice] = "Hierarchy updated"
        redirect_to :action => 'index', :id => @hierarchy.id 
      end
    end
  end
end
