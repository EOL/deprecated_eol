class Taxa::TreesController < TaxaController
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid

  def show
    @include_common_names = true
    @hierarchy_entry = @taxon_concept.find_ancestor_in_hierarchy(@selected_hierarchy_entry.hierarchy)
    # TODO - an error if the hierarchy_entry is blank
    @hierarchy = @hierarchy_entry.hierarchy
    render :partial => 'navigation/browse_page', :layout => false
  end

end
