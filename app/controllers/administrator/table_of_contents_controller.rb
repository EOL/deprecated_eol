class Administrator::TableOfContentsController < AdminController
  helper_method :current_agent, :agent_logged_in?
  layout :admin_unless_ajax
  
  access_control :DEFAULT => 'Administrator - Site CMS'
  
  def index
    @page_title = 'Table of Contents'
  end
  
  def show_tree
    render :layout => false, :partial => 'show_tree'
  end
  
  def move_up
    if toc = TocItem.find(params[:id])
      toc.move_up
    end
    render :layout => false, :partial => 'show_tree'
  end
  
  def move_down
    if toc = TocItem.find(params[:id])
      toc.move_down
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
  
  
  def admin_unless_ajax
    layout = (["show_tree"].include? action_name) ? nil : 'admin'
  end
  
end
