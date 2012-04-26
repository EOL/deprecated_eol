class Taxa::TreesController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded

  def show
    @hierarchy_entry = @selected_hierarchy_entry ? 
      @taxon_concept.find_ancestor_in_hierarchy(@selected_hierarchy_entry.hierarchy) :
      @taxon_concept.entry 
    # TODO - an error if the hierarchy_entry is blank
    render :layout => false
  end

end
