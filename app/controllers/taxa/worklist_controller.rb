class Taxa::WorklistController < TaxaController

  before_filter :check_authentication
  before_filter :restrict_to_curators
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    @sort_by = params[:sort_by] ||= 'created_at'
    @object_type = params[:object_type] ||= 'all'
    @object_status = params[:object_status] ||= 'unknown'
    @object_visibility = params[:object_visibility] ||= 'visible'
    @task_status = params[:task_status] ||= 'active'
    # checking approved values
    @object_type = 'all' unless ['all', 'text', 'image', 'video', 'sound'].include?(@object_type)
    @object_status = 'trusted' unless ['trusted', 'unknown', 'untrusted'].include?(@object_status)
    @object_visibility = 'visible' unless ['visible', 'invisible'].include?(@object_visibility)
    @task_status = 'active' unless ['active', 'curated', 'ignored'].include?(@task_status)
    
    data_type_id = nil
    if data_type = DataType.cached_find_translated(:label, params[:object_type], 'en')
      data_type_id = data_type.id
    end
    
    
    @data_objects = EOL::Solr::DataObjects.search_with_pagination(@taxon_concept.id, {
      :sort_by => @sort_by,
      :data_type_id => data_type_id,
      :vetted_type => @object_status,
      :visibility_type => @object_visibility,
      :filter => @task_status
    })
    
    @current_data_object = @data_objects.detect{ |ct| ct.id == params[:current].to_i } unless params[:current].blank?
    @current_data_object = @data_objects.first if @current_data_object.blank?
    params[:current] = @current_data_object.id
  end
  
  def data_objects
    @current_data_object = DataObject.find(params[:data_object_id])
    params[:return_to] = taxon_worklist_path(@taxon_concept.id)
    render(:partial => 'curation_content')
  end
private

  def redirect_if_superceded
    redirect_to taxon_worklist_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
  end
end
