class ConceptManagerController < ApplicationController
  include ApiHelper
  
  layout 'concept_manager'
  
  def index
  
  end
  
  def lookup_concept
    @taxon_concept = TaxonConcept.find(params[:id])
    render :partial => 'concept_entry_list'
  end
  
  def lookup_entry
    hierarchy_entry = HierarchyEntry.find(params[:id])
    @taxon_concept = hierarchy_entry.taxon_concept
    render :partial => 'concept_entry_list'
  end
  
end
