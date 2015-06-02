class NavigationController < ApplicationController

  # caches_page :flash_tree_view

  def show_tree_view
    # set the users default hierarchy if they haven't done so already
    @selected_hierarchy_entry = HierarchyEntry.find_by_id(params[:selected_hierarchy_entry_id].to_i)
    @taxon_page = TaxonPage.new(@taxon_concept, current_user, @selected_hierarchy_entry)
    @session_hierarchy = @taxon_page.hierarchy
    load_taxon_for_tree_view
    render layout: false, partial: 'root_nodes'
  end
  
  def show_tree_view_for_selection
    load_taxon_for_tree_view
    render layout: false, partial: 'tree_view_for_selection'
  end
  
  def browse
    @hierarchy_entry = HierarchyEntry.find_by_id(params[:id])
    expand = params[:expand] == "1"
    if @hierarchy_entry.blank?
      return
    end
    @hierarchy = @hierarchy_entry.hierarchy
    render layout: false, partial: 'browse', locals: { expand: expand }
  end
  
  def browse_stats
    @hierarchy_entry = HierarchyEntry.find_by_id(params[:id])
    expand = params[:expand] == "1"
    if @hierarchy_entry.blank?
      return
    end
    @hierarchy = @hierarchy_entry.hierarchy
    render partial: 'browse_stats', layout: false, locals: { expand: expand }
  end
  
  
  protected
  
  def load_taxon_for_tree_view
    @hierarchy_entry = HierarchyEntry.find(params[:id].to_i)
  end
  
end
