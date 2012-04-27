class Taxa::TreesController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded

  def show
    @hierarchy_entry = @selected_hierarchy_entry ? 
      @taxon_concept.find_ancestor_in_hierarchy(@selected_hierarchy_entry.hierarchy) :
      @taxon_concept.entry 
    @max_children = params[:full] ? 20000 : nil
    render :layout => false
  end

end
