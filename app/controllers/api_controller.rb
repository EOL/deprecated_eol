class ApiController < ApplicationController
  def pages
    taxon_concept_id = params[:id] || 0
    params[:images] ||= 1
    params[:text] ||= 1
    params[:vetted] ||= false
    params[:common_names] ||= false
    params[:images] = 75 if params[:images].to_i > 75
    params[:text] = 75 if params[:text].to_i > 75
    params[:details] = 1 if params[:format] == 'html'
    
    taxon_concept = TaxonConcept.find(taxon_concept_id)
    unless taxon_concept.nil? || !taxon_concept.published?
      details_hash = taxon_concept.details_hash(:return_media_limit => params[:images].to_i, :subjects => params[:subjects], :return_text_limit => params[:text].to_i, :details => params[:details], :vetted => params[:vetted], :common_names => params[:common_names])
    end
    if params[:format] == 'html'
      render(:partial => 'pages', :layout=>false, :locals => {:details_hash => details_hash, :data_object_details => true } )
    else
      respond_to do |format|
         format.xml { render(:partial => 'pages', :layout=>false, :locals => {:details_hash => details_hash, :data_object_details => params[:details] } ) }
      end
    end
  end
  
  def data_objects
    data_object_guid = params[:id] || 0
    params[:common_names] ||= false
    
    details_hash = DataObject.details_for_object(data_object_guid, :include_taxon => true, :common_names => params[:common_names])
    if params[:format] == 'html'
      render(:partial => 'pages', :layout => false, :locals => { :details_hash => details_hash, :data_object_details => true } )
    else
      respond_to do |format|
        format.xml { render(:partial => 'pages', :layout => false, :locals => { :details_hash => details_hash, :data_object_details => true } ) }
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
