class Taxa::TreesController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded

  def show
    @include_common_names = false
    @hierarchy_entry = @taxon_concept.find_ancestor_in_hierarchy(@selected_hierarchy_entry.hierarchy)
    # TODO - an error if the hierarchy_entry is blank
    @hierarchy = @hierarchy_entry.hierarchy
    render :layout => false
  end

end
