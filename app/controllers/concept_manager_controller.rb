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
  
  def supercede_concepts
    id1 = params[:id1]
    id2 = params[:id2]
    raise 'Invalid id1' if id1.blank? || !id1.is_int? || id1.to_i == 0
    raise 'Invalid id2' if id2.blank? || !id2.is_int? || id2.to_i == 0
    
    # success = TaxonConcept.supercede_by_ids(id1.to_i, id2.to_i)
    success = false
    if success
      render :text => 'success'
    else
      raise 'Failure to supercede'
    end
  end
  
  def split_entry_from_concept
    id = params[:id]
    raise 'Invalid id' if id.blank? || !id.is_int? || id.to_i == 0
    
    begin
      hierarchy_entry = HierarchyEntry.find(id)
    rescue
      raise 'Invalid HierarchyEntry ID'
    end
    
    
    # new_taxon_concept = hierarchy_entry.split_from_concept
    success = false
    if new_taxon_concept
      render :text => new_taxon_concept.id
    else
      raise 'Failure to split'
    end
  end
  
end
