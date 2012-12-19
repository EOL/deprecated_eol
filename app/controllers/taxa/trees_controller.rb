class Taxa::TreesController < TaxaController
  skip_before_filter :original_request_params, :global_warning, :set_locale, :check_user_agreed_with_terms,:redirect_if_superceded

  def show
    @hierarchy_entry = HierarchyEntry.find(params[:entry_id])
    params.each do |k,v|
      params[k] = false if v == 'false'
    end
    @max_children = params[:full] ? 20000 : nil
    @link_to_taxa = params[:link_to_taxa]
    @show_siblings = params[:show_siblings]
    @show_hierarchy_label = params[:show_hierarchy_label]
    render :layout => false
  end

end
