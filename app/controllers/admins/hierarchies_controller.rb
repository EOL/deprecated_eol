#class Administrator::HierarchyController < AdminController
class Admins::HierarchiesController < AdminsController


  #layout 'left_menu'

  #before_filter :set_layout_variables

  helper :resources

  helper_method :current_agent, :agent_logged_in?

  before_filter :restrict_to_admins

  def index
    page = params[:page] || '1'
    order = params[:order_by] || 'agent'

    @page_title = I18n.t("hierarchies_")
    hierarchies = Hierarchy.find(:all, :include => [ :agent, { :resource => { :content_partner => :user } } ])
    case order
      when 'label'
        hierarchies = hierarchies.sort_by{ |h| h.form_label }
      when 'browsable'
        hierarchies = Hierarchy.sort_by_user_or_agent_name(hierarchies)
      else
        hierarchies = hierarchies.sort_by{ |h| h.user_or_agent_or_label_name }
      end
    @hierarchies = hierarchies.paginate(:page => page)
  end

  def show
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
  end

  def update
    @hierarchy = Hierarchy.find_by_id(params[:id])
    if @hierarchy.blank?
      redirect_to :action=>'index'
      return
    end
    if params[:hierarchy][:browsable] == "1"
      params[:hierarchy][:request_publish] = false
    end
    if @hierarchy.update_attributes(params[:hierarchy])
      # if there were changes to what was browsable we want those changes immediately visible
      $CACHE.delete('hierarchies/browsable_by_label')
      flash.now[:notice] = I18n.t("hierarchy_updated")
      redirect_to :action => 'index', :id => @hierarchy.id
    end
  end


private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
