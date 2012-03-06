class Taxa::WorklistController < TaxaController

  before_filter :check_authentication
  before_filter :restrict_to_curators
  before_filter :instantiate_taxon_concept, :redirect_if_superceded, :instantiate_preferred_names
  before_filter :add_page_view_log_entry

  def show
    @page = params[:page] ||= 1
    @sort_by = params[:sort_by] ||= 'newest'
    @object_type = params[:object_type] ||= 'all'
    @object_status = params[:object_status] ||= 'unreviewed'
    @object_visibility = params[:object_visibility] ||= 'visible'
    @task_status = params[:task_status] ||= 'active'
    @resource_id = params[:resource_id] ||= 'all'
    # checking approved values
    @sort_by = 'newest' unless ['newest', 'oldest', 'rating'].include?(@sort_by)
    @object_type = 'all' unless ['all', 'text', 'image', 'video', 'sound'].include?(@object_type)
    @object_status = 'all' unless ['all', 'trusted', 'unreviewed', 'untrusted'].include?(@object_status)
    @object_visibility = 'all' unless ['all', 'visible', 'invisible'].include?(@object_visibility)
    @task_status = 'active' unless ['active', 'curated', 'ignored'].include?(@task_status)
    # TODO: active means NOT curated and NOT ignored
    @resource_id = 'all' unless @resource_id == 'all' || @resource_id.is_numeric?
    @resource_id = nil if @resource_id == 'all'
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
    search_options = {
      :page => @page,
      :per_page => 16,
      :sort_by => @sort_by,
      :data_type_ids => data_type_ids,
      :vetted_types => search_vetted_types,
      :visibility_types => [ @object_visibility ],
      :return_hierarchically_aggregated_objects => true,
      :user => current_user,
      :resource_id => @resource_id,
      :facet_by_resource => true
    }
    if @task_status == 'active'
      search_options[:curated_by_user] = false
      search_options[:ignored_by_user] = false
    elsif @task_status == 'curated'
      search_options[:curated_by_user] = true
    elsif @task_status == 'ignored'
      search_options[:ignored_by_user] = true
    end
    
    @data_objects = @taxon_concept.data_objects_from_solr(search_options)
    @resource_counts = EOL::Solr::DataObjects.load_resource_facets(@taxon_concept.id,
      search_options.merge({ :resource_id => nil })).sort_by{ |c| c[:resource].title.downcase }

    @current_data_object = @data_objects.detect{ |ct| ct.id == params[:current].to_i } unless params[:current].blank?
    @current_data_object = @data_objects.first if @current_data_object.blank?
    params[:current] = @current_data_object.id if @current_data_object
    params.delete(:worklist_return_to)
    params.delete(:data_object_id)
    if @current_data_object
      preload_object
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
    preload_object
    params.delete(:worklist_return_to)
    params.delete(:data_object_id)
    params.delete(:action)
    params[:worklist_return_to] = taxon_worklist_data_object_path(@taxon_concept, @current_data_object)
    params[:force_return_to] = taxon_worklist_data_object_path(@taxon_concept, @current_data_object)
    render(:partial => 'curation_content')
  end
  
  private
  def preload_object
    DataObject.preload_associations(@current_data_object,
      [ { :data_object_translation => { :original_data_object => :language } },
        { :translations => { :data_object => :language } },
        { :agents_data_objects => [ :agent, :agent_role ] },
        { :data_objects_hierarchy_entries => { :hierarchy_entry => [ :name, :taxon_concept, :vetted, :visibility ] } },
        { :curated_data_objects_hierarchy_entries => { :hierarchy_entry => [ :name, :taxon_concept, :vetted, :visibility ] } } ] )
    @revisions = DataObject.sort_by_created_date(@current_data_object.revisions).reverse
    @activity_log = @current_data_object.activity_log(:ids => @revisions.collect{ |r| r.id }, :page => @page || nil)
  end
end
