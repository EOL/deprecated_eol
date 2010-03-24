class ApiController < ApplicationController
  def pages
    taxon_concept_id = params[:id] || 0
    params[:images] ||= 1
    params[:text] ||= 1
    @complete_objects = params[:details]
    
    params[:images] = 30 if params[:images].to_i > 30
    params[:text] = 30 if params[:text].to_i > 30
    
    taxon_concept = TaxonConcept.find(taxon_concept_id)
    unless taxon_concept.nil? || !taxon_concept.published?
      @details_hash = taxon_concept.details_hash(:return_media_limit => params[:images].to_i, :subject => params[:subject], :return_text_limit => params[:text].to_i, :details => params[:details])
    end
    
    if params[:format] == 'html'
      render :layout => false
    else
      respond_to do |format|
         format.xml { render :layout=>false }
      end
    end
  end
  
  def data_objects
    data_object_guid = params[:id] || 0
    
    @details_hash = DataObject.details_for_object(data_object_guid)
    if params[:format] == 'html'
      render :layout => false
    else
      respond_to do |format|
        format.xml { render :layout=>false }
      end
    end
  end
  
  def search
    @search_term = params[:id]
    @page = params[:page].to_i || 1
    @page = 1 if @page < 1
    
    @results = TaxonConcept.search_with_pagination(@search_term, :page => @page, :per_page => 30, :type => :all, :return_raw_response => true)
    @results = @results['response']['docs'].paginate(:page => params[:page], :per_page => 30)
    @last_page = @results.total_pages
    
    respond_to do |format|
       format.xml { render :layout=>false }
    end
  end
end
