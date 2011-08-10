class Taxa::WorklistController < TaxaController

  before_filter :check_authentication
  before_filter :restrict_to_curators
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    # TODO - Note, I'm assigning @taxon_concept.data_objects to the @worklist_tasks just to get the functionality working on the interface.
    # It should be replaced to get the data_objects for the given taxon_concept using the SOLR.
    @worklist_tasks = @taxon_concept.data_objects 
    
    @object_type = params[:object_type] ||= 'all'
    @object_status = params[:object_status] ||= 'unknown'
    @object_visibility = params[:object_visibility] ||= 'visible'
    @task_status = params[:task_status] ||= 'active'
    unless @object_type.blank? && (@object_type.blank? || @object_type == 'all')
      @worklist_tasks = DataObject.custom_filter(@worklist_tasks, @taxon_concept, @object_type, @object_status)
    end
    @worklist_tasks.each do |wt|
      wt['revisions'] = wt.revisions.sort_by(&:created_at).reverse
    end
    @current_task = @worklist_tasks.detect{ |ct| ct.id == params[:current].to_i } unless params[:current].blank?
    @current_task = @worklist_tasks.first if @current_task.blank?
  end

private

  def redirect_if_superceded
    redirect_to taxon_worklist_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
  end
end
