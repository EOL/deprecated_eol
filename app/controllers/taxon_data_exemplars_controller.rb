class TaxonDataExemplarsController < ApplicationController

  before_filter :restrict_to_full_curators

  def create
    parent = case params[:type]
             when "UserAddedData"
               UserAddedData.find(params[:id])
             when "DataPointUri"
               DataPointUri.find(params[:id])
             end
    raise "Couldn't find a parent of type #{params[:type]} with ID #{params[:id]}" if parent.nil?
    TaxonDataExemplar.create(taxon_concept_id: params[:taxon_concept_id], parent: parent)
    flash[:notice] = I18n.t(:data_row_exemplar_added)
    redirect_to taxon_data_path(params[:taxon_concept_id])
  end

  def destroy
    c = TaxonDataExemplar.delete_all(taxon_concept_id: params[:taxon_concept_id], parent_type: params[:type], parent_id: params[:id])
    if c && c > 0
      flash[:notice] = I18n.t(:data_row_exemplar_removed)
    end
    redirect_to taxon_data_path(params[:taxon_concept_id])
  end

end
