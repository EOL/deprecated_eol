class ApiController < ApplicationController
  def taxon_concept_details
    taxon_concept_id = params[:id] || 0
    params[:media_count] ||= 1
    params[:text_count] ||= 1
    
    taxon_concept = TaxonConcept.find(taxon_concept_id)
    unless taxon_concept.nil? || !taxon_concept.published?
      @details_hash = taxon_concept.details_hash(:return_media_limit => params[:media_count].to_i, :subject => params[:subject], :return_text_limit => params[:text_count].to_i)
    end
    
    respond_to do |format|
       format.xml { render :layout=>false }
    end
  end
  
  def data_object_details
    data_object_guid = params[:id] || 0
    
    @details_hash = DataObject.details_for_object(data_object_guid)
    
    respond_to do |format|
       format.xml { render :layout=>false }
    end
  end
end
