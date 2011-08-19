class Taxa::WorklistController < TaxaController

  before_filter :check_authentication
  before_filter :restrict_to_curators
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :redirect_if_invalid
  before_filter :add_page_view_log_entry, :update_user_content_level

  def show
    @page = params[:page] ||= 1
    @sort_by = params[:sort_by] ||= 'newest'
    @object_type = params[:object_type] ||= 'all'
    @object_status = params[:object_status] ||= 'unreviewed'
    @object_visibility = params[:object_visibility] ||= 'visible'
    @task_status = params[:task_status] ||= 'active'
    # checking approved values
    @sort_by = 'newest' unless ['newest', 'oldest', 'rating'].include?(@sort_by)
    @object_type = 'all' unless ['all', 'text', 'image', 'video', 'sound'].include?(@object_type)
    @object_status = 'all' unless ['all', 'trusted', 'unreviewed', 'untrusted'].include?(@object_status)
    @object_visibility = 'all' unless ['all', 'visible', 'invisible'].include?(@object_visibility)
    @task_status = 'active' unless ['active', 'curated', 'ignored'].include?(@task_status)
    
    data_type_ids = nil
    if params[:object_type] == 'video'
      data_type_ids = DataType.video_type_ids
    elsif data_type = DataType.cached_find_translated(:label, params[:object_type], 'en')
      data_type_ids = [data_type.id]
    end
    
    search_vetted_types = [ @object_status ]
    if search_vetted_types == ['all']
      search_vetted_types = ['trusted', 'unreviewed', 'untrusted']
    end
    @data_objects = EOL::Solr::DataObjects.search_with_pagination(@taxon_concept.id, {
      :page => @page,
      :per_page => 16,
      :sort_by => @sort_by,
      :data_type_ids => data_type_ids,
      :vetted_types => search_vetted_types,
      :visibility_types => [ @object_visibility ],
      :user => current_user,
      :filter => @task_status
    })
    
    @current_data_object = @data_objects.detect{ |ct| ct.id == params[:current].to_i } unless params[:current].blank?
    @current_data_object = @data_objects.first if @current_data_object.blank?
    params[:current] = @current_data_object.id if @current_data_object
    params.delete(:worklist_return_to)
    params.delete(:data_object_id)
    if @current_data_object
      params[:worklist_return_to] = taxon_worklist_data_object_path(@taxon_concept, @current_data_object)
      params[:force_return_to] = taxon_worklist_data_object_path(@taxon_concept, @current_data_object)
    end
    
    unless params[:ajax].blank?
      params.delete(:ajax)
      render(:partial => 'main_content')
      return
    end
  end
  
  def data_objects
    @current_data_object = DataObject.find(params[:data_object_id])
    params.delete(:worklist_return_to)
    params.delete(:data_object_id)
    params.delete(:action)
    params[:worklist_return_to] = taxon_worklist_data_object_path(@taxon_concept, @current_data_object)
    params[:force_return_to] = taxon_worklist_data_object_path(@taxon_concept, @current_data_object)
    render(:partial => 'curation_content')
  end
  
  def data_objects
    @current_data_object = DataObject.find(params[:data_object_id])
    params.delete(:worklist_return_to)
    params.delete(:data_object_id)
    params.delete(:action)
    params[:worklist_return_to] = taxon_worklist_data_object_path(@taxon_concept, @current_data_object)
    params[:force_return_to] = taxon_worklist_data_object_path(@taxon_concept, @current_data_object)
    render(:partial => 'curation_content')
  end

private

  def redirect_if_superceded
    redirect_to taxon_worklist_path(@taxon_concept, params.merge(:status => :moved_permanently).
        except(:controller, :action, :id, :taxon_id)) and return false if @taxon_concept.superceded_the_requested_id?
  end
end
