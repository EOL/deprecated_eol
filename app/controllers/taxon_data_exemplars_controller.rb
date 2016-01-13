class TaxonDataExemplarsController < ApplicationController

  before_filter :restrict_to_full_curators
  after_filter :flush_cache , only: :create

  def create
    @data_point_uri = DataPointUri.find(params[:id])
    raise "Couldn't find a DataPointUri with ID #{params[:id]}" if @data_point_uri.nil?
    # Simply to avoid using #update (thus cleaner code, though a bit less RESTful), we'll just delete anything that already exists:
    TaxonDataExemplar.delete_all(taxon_concept_id: params[:taxon_concept_id], data_point_uri_id: @data_point_uri.id)
    exclude = params.has_key?(:exclude) && params[:exclude] # Argh! For whatever reason, nils are stored as nil in the DB and that breaks scopes.
    @taxon_data_exemplar = TaxonDataExemplar.create(taxon_concept_id: params[:taxon_concept_id], data_point_uri: @data_point_uri, exclude: exclude )
    # TODO - if there are too many exemplars (more than are allowed), we need to give them a warning or something.  Sadly, that
    # is expensive to calculate...  Hmmmn...
    log_action(params[:taxon_concept_id], @data_point_uri, :set_exemplar_data) unless exclude
    respond_to do |format|
      format.html do
        if @taxon_data_exemplar
          flash[:notice] = exclude ? I18n.t(:data_row_exemplar_removed) : flash[:notice] = I18n.t(:data_row_exemplar_added)
        end
        redirect_to taxon_data_path(params[:taxon_concept_id])
      end
      format.js { }
    end
  end

  private

  def log_action(taxon_concept_id, data_point_uri, method)
    CuratorActivityLog.create(
      user_id: current_user.id,
      changeable_object_type: ChangeableObjectType.data_point_uri,
      target_id: data_point_uri.id,
      activity: Activity.send(method),
      taxon_concept_id: taxon_concept_id
    )
  end

  def flush_cache
    expire_fragment("overview/#{@data_point_uri.taxon_concept_id}/traits/#{current_language}", skip_digest: true)
  end
end
