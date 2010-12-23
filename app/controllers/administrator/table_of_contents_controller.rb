class Administrator::TableOfContentsController < AdminController

  helper_method :current_agent, :agent_logged_in?
  layout :admin_unless_ajax
  
  access_control Privilege.site_cms
  
  def index
    @page_title = 'Table of Contents'
  end
  
  def show_tree
    render :layout => false, :partial => 'show_tree'
  end
  
  def move_up
    if toc = TocItem.find(params[:id])
      toc.move_up(params[:top] == "true")
    end
    render :layout => false, :partial => 'show_tree'
  end
  
  def move_down
    if toc = TocItem.find(params[:id])
      toc.move_down(params[:bottom] == "true")
    end
    render :layout => false, :partial => 'show_tree'
  end
  
  def create
    if !params[:parent_id].blank? && !params[:label].blank?
      if params[:parent_id] == '0'
        TocItem.add_major_chapter(params[:label])
      elsif parent = TocItem.find(params[:parent_id])
        parent.add_child(params[:label])
      end
    end
    render :layout => false, :partial => 'show_tree'
  end
  
  def update
    if !params[:label].blank?
      if toc_item = TocItem.find(params[:id])
        toc_item.label = params[:label]
        toc_item.save
      end
    end
    render :layout => false, :partial => 'show_tree'
  end
  
private

  def admin_unless_ajax
    @page_title = $ADMIN_CONSOLE_TITLE
    @navigation_partial = '/admin/navigation'
    layout = (["show_tree"].include? action_name) ? nil : 'left_menu'
  end
  
end
