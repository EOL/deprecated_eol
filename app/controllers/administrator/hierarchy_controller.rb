class Administrator::HierarchyController < AdminController

  # TODO - this doesn't appear to be used anywhere.  So:
  # Check all translations, remove i18n keys from config/locales/en.yml if they are unused
  # Check methods called; if they are not used elsewhere, delete.
  # Check views; if unused elsewhere, delete.
  # Delete this controller.

  layout 'left_menu'

  helper :resources

  before_filter :set_layout_variables
  before_filter :restrict_to_admins

  def index
    page = params[:page] || '1'
    order = params[:order_by] || 'agent'

    @page_title = I18n.t("hierarchies_title")
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

  def browse
    @hierarchy = Hierarchy.find_by_id(params[:id])
    if @hierarchy.blank?
      redirect_to :action=>'index', :status => :moved_permanently
      return
    end
  end

  def edit
    @hierarchy = Hierarchy.find_by_id(params[:id])
    if @hierarchy.blank?
      redirect_to :action=>'index', :status => :moved_permanently
      return
    end
    if request.post?
      if params[:hierarchy][:browsable] == "1"
        params[:hierarchy][:request_publish] = false
      end
      if @hierarchy.update_attributes(params[:hierarchy])
        # if there were changes to what was browsable we want those changes immediately visible
        $CACHE.delete('hierarchies/browsable_by_label')
        flash[:notice] = I18n.t("hierarchy_updated")
        redirect_to :action => 'index', :id => @hierarchy.id, :status => :moved_permanently
      end
    end
  end

private

  def set_layout_variables
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
  end

end
