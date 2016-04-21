class RaffleController < ApplicationController
  layout 'collections'
  def index
    # @taxon_concept = TaxonConcept.find 13
    # @selected_hierarchy_entry = HierarchyEntry.find_by_id(8)
    # @taxon_page = TaxonPage.new(@taxon_concept, current_user, @selected_hierarchy_entry)
    # @session_hierarchy = @taxon_page.hierarchy
    # @hierarchy_entry = HierarchyEntry.find(8)
    # @roots = HierarchyEntry.sort_by_name(@taxon_page.hierarchy.kingdoms(:common_name_language => current_language))
    
    respond_to do |format|
      format.html {}
      format.js{}
    end
  end
end
