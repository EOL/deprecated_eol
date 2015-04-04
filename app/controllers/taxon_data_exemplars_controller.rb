class TaxonDataExemplarsController < ApplicationController

  before_filter :restrict_to_full_curators

  # TODO: move this to traits controller!
  def create
    @trait = Trait.find(params[:id])
    exclude = params.has_key?(:exclude) && params[:exclude]
    worked = @trait.update_attributes(overview_include: !exclude,
      overview_exclude: exclude)
    # TODO - if there are too many exemplars (more than are allowed), we need to
    # give them a warning or something.
    log_action(params[:taxon_concept_id], @trait, :set_exemplar_data) unless exclude
    respond_to do |format|
      format.html do
        if worked
          flash[:notice] = exclude ? I18n.t(:data_row_exemplar_removed) : flash[:notice] = I18n.t(:data_row_exemplar_added)
        end
        redirect_to taxon_data_path(params[:taxon_concept_id])
      end
      format.js { }
    end
  end

  private

  def log_action(taxon_concept_id, trait, method)
    CuratorActivityLog.create(
      user_id: current_user.id,
      changeable_object_type: ChangeableObjectType.trait,
      target_id: trait.id,
      activity: Activity.send(method),
      taxon_concept_id: taxon_concept_id
    )
  end
end
