class HierarchyEntriesController < ApplicationController

  # GET /pages/:taxon_id/entries/:id/
  def show
    hierarchy_entry_id = params[:id]
    redirect_to overview_taxon_entry_path(params[:taxon_id], hierarchy_entry_id)
  end

  # POST /pages/:taxon_id/entries/:id/switch
  def switch
    hierarchy_entry_id = params[:hierarchy_entry][:id] if params[:hierarchy_entry]
    unless hierarchy_entry_id
      flash[:notice] = I18n.t(:hierarchy_entry_switch_missing_id_error)
      hierarchy_entry_id ||= params[:id]
    end
    if params[:return_to]
      return_to_params = ActionController::Routing::Routes.recognize_path(params[:return_to], :method => :get)
      return_to_params[:hierarchy_entry_id] = hierarchy_entry_id
      store_location url_for(return_to_params)
    end
    redirect_back_or_default overview_taxon_entry_path(params[:taxon_id], hierarchy_entry_id)
  end

end
