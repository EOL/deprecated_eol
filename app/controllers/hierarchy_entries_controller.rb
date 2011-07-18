class HierarchyEntriesController < ApplicationController

  def show
    hierarchy_entry_id = params[:id]
    redirect_to taxon_hierarchy_entry_overview_path(params[:taxon_id], hierarchy_entry_id)
  end

end
