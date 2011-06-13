class DataObjectsController < ApplicationController

  # No layout for Ajax calls.  Everthing else uses main:
  layout proc { |c| c.request.xhr? ? false : "v2/data" }

  before_filter :load_data_object, :except => [:index, :new, :create, :preview]
  before_filter :allow_login_then_submit, :only => [:rate]
  before_filter :curator_only, :only => [:curate, :add_association, :remove_association]

  def create
    params[:references] = params[:references].split("\n") unless params[:references].blank?
    data_object = DataObject.create_user_text(params, current_user)
    @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
    @curator = current_user.can_curate?(@taxon_concept)
    @taxon_concept.current_user = current_user
    @category_id = data_object.toc_items[0].id
    alter_current_user do |user|
      user.vetted=false
    end
    current_user.log_activity(:created_data_object_id, :value => data_object.id, :taxon_concept_id => @taxon_concept.id)
    render(:partial => '/taxa/text_data_object',
           :locals => {:content_item => data_object, :comments_style => '', :category => data_object.toc_items[0].label})
  end

  def preview
    begin
      params[:references] = params[:references].split("\n")
      data_object = DataObject.preview_user_text(params, current_user)
      @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
      @taxon_concept.current_user = current_user
      @curator = false
      @preview = true
      @data_object_id = params[:id]
      @hide = true
      current_user.log_activity(:previewed_data_object, :taxon_concept_id => @taxon_concept.id)
      render :partial => '/taxa/text_data_object', :locals => {:content_item => data_object, :comments_style => '', :category => data_object.toc_items[0].label}
    rescue => e
      @message = e.message
    end
  end

  def get
    @taxon_concept = TaxonConcept.find params[:taxon_concept_id] if params[:taxon_concept_id]
    @taxon_concept.current_user = current_user
    @curator = current_user.can_curate?(@taxon_concept)
    @hide = true
    @category_id = @data_object.toc_items[0].id
    @text = render_to_string(:partial => '/taxa/text_data_object', :locals => {:content_item => @data_object, :comments_style => '', :category => @data_object.toc_items[0].label})
    render(:partial => '/taxa/text_data_object', :locals => {:content_item => @data_object, :comments_style => '', :category => @data_object.toc_items[0].label})
  end

  def update
    params[:references] = params[:references].split("\n")
    @taxon_concept = TaxonConcept.find params[:taxon_concept_id] if params[:taxon_concept_id]
    @taxon_concept.current_user = current_user
    @old_data_object_id = params[:id]
    @data_object = DataObject.update_user_text(params, current_user)
    @curator = current_user.can_curate?(@taxon_concept)
    @hide = true
    @category_id = @data_object.toc_items[0].id
    alter_current_user do |user|
      user.vetted=false
    end
    current_user.log_activity(:updated_data_object_id, :value => @data_object.id, :taxon_concept_id => @taxon_concept.id)
    render(:partial => '/taxa/text_data_object', :locals => {:content_item => @data_object, :comments_style => '', :category => @data_object.toc_items[0].label})
  end

  def edit
    set_text_data_object_options
    @taxon_concept = TaxonConcept.find params[:taxon_concept_id] if params[:taxon_concept_id]
    @selected_language = [@data_object.language.label,@data_object.language.id]
    @selected_license = [@data_object.license.title,@data_object.license.id]
    current_user.log_activity(:editing_data_object, :taxon_concept_id => @taxon_concept.id)
    render :partial => 'edit_text'
  end

  def new
    if(logged_in?)
      @taxon_concept = TaxonConcept.find(params[:taxon_concept_id])
      @selected_license = [License.by_nc.title,License.by_nc.id]
      @selected_language = [current_user.language.label,current_user.language.id]
      @toc_id_empty = params[:toc_id] == 'none'
      if (@toc_id_empty)
        @taxon_concept.current_user = current_user
        toc_item = @taxon_concept.tocitem_for_new_text
        params[:toc_id] = toc_item.id
      end
      set_text_data_object_options
      @data_object = DataObject.new
      render :partial => 'new_text'
      current_user.log_activity(:creating_new_data_object, :taxon_concept_id => @taxon_concept.id)
    else
      if $ALLOW_USER_LOGINS
        render :partial => 'login_for_text'
      else
        render :text => 'New text cannot be added at this time. Please try again later.'
      end
    end
  end

  def curator_only
    if !current_user.can_curate?(@data_object)
      raise Exception.new('Not logged in as curator')
    end
  end

  def rate

    if session[:submitted_data]
      stars = session[:submitted_data][:stars]
      return_to = session[:submitted_data][:return_to]
      session.delete(:submitted_data)
    end

    stars ||= params[:stars]
    return_to ||= params[:return_to]

    store_location(return_to)

    if stars.to_i > 0
      @data_object.rate(current_user, stars.to_i)
      expire_data_object(@data_object.id)
      current_user.log_activity(:rated_data_object_id, :value => @data_object.id)
    end

    respond_to do |format|
      format.html { redirect_back_or_default }
      # format.js {render :action => 'rate.rjs'} #TODO
    end
  end

  def show
    @page_title = page_title
    get_attribution
    @feed_item = FeedItem.new(:feed_id => @data_object.id, :feed_type => @data_object.class.name)
    @type = @data_object.data_type.label
    @comments = @data_object.all_comments.dup.paginate(:page => params[:page], :order => 'updated_at DESC', :per_page => Comment.per_page)
    @slim_container = true
    @revisions = @data_object.revisions.sort_by(&:created_at).reverse
    @taxon_concepts = @data_object.get_taxon_concepts(:published => :preferred)
    @scientific_names = @taxon_concepts.inject({}) { |res, tc| res[tc.scientific_name] = { :common_name => tc.common_name, :taxon_concept_id => tc.id }; res }
    @image_source = get_image_source if @type == 'Image'
  end

  def page_title
    @taxon_concepts = @data_object.get_taxon_concepts(:published => :preferred)
    if @taxon_concepts[0].published?
      @taxon_concepts.each do |t|
        tc_label = t.scientific_name
        tc_label += ": #{t.common_name}" unless t.common_name.blank?
      end
    else
      @taxon_concepts.each do |t|
        names = @taxon_concepts.map { |item| t.scientific_name + (t.common_name.blank? ? '' : ": <b>#{t.common_name}</b>") }.uniq
        tc_label = "associated with the deprecated page#{names.size == 1 ? '' : 's'}: '#{names.join("', '")}')"
      end
    end
    return tc_label ||= ""
  end

  # GET /data_objects/1/attribution
  def attribution
    get_attribution
    render :partial => 'attribution', :locals => { :data_object => @data_object }, :layout => @layout
  end

  # GET /data_objects/1/curation
  # GET /data_objects/1/curation.js
  #
  # UI for curating a data object
  #
  # This is a GET, so there's no real reason to check to see
  # whether or not the current_user can_curate the object -
  # we leave that to the #curate method
  #
  def curation
  end

  def remove_association
    @data_object.remove_curated_association(current_user, HierarchyEntry.find(params[:hierarchy_entry_id]))
    redirect_to data_object_path(@data_object)
  end

  def add_association
    @name = params[:add_association]
    # TODO - handle the case where they didn't enter a name at all.
    @entries = entries_for_name(@name)
    if @entries.length == 1
      @data_object.add_curated_association(current_user, @entries.first)
      redirect_to data_object_path(@data_object)
    end
  end

  def curate_associations
    @data_object.published_entries.each do |phe|
      all_params = { :vetted_id => params["vetted_id_#{phe.id}"],
                     :visibility_id => params["visibility_id_#{phe.id}"],
                     :curation_comment => params["curation_comment_#{phe.id}"],
                     :untrust_reason_ids => params["untrust_reasons_#{phe.id}"],
                     :untrust_reasons_comment => params["untrust_reasons_comment_#{phe.id}"],
                     :curate_vetted_status => phe.vetted_id != params["vetted_id_#{phe.id}"].to_i,
                     :curate_visibility_status => phe.visibility_id != params["visibility_id_#{phe.id}"].to_i,
                     :curation_comment_status => !params["curation_comment_#{phe.id}"].blank?,
                     }
      @data_object.curate_association(current_user, phe, all_params)
    end
    redirect_to data_object_path(@data_object)
  end

protected

  def entries_for_name(name)
    # TODO - This should use search, not Name.
    Name.find_by_string(name).hierarchy_entries
  end

  def load_data_object
    @data_object ||= DataObject.find(params[:id])
  end

  def get_attribution
    current_user.log_activity(:showed_attributions_for_data_object_id, :value => @data_object.id)
  end

  def set_text_data_object_options
    @selectable_toc = TocItem.selectable_toc
    toc = TocItem.find(params[:toc_id])
    @selected_toc = [toc.label, toc.id]
    @languages = Language.find_by_sql("SELECT * FROM languages WHERE iso_639_1!=''").collect {|c| [c.label.truncate(30), c.id] }
    @licenses = License.valid_for_user_content
  end

  def get_image_source
    case params[:image_size]
    when 'small'
      @data_object.smart_thumb
    when 'medium'
      @data_object.smart_medium_thumb
    when 'original'
      @data_object.original_image
    else
      @data_object.smart_image
    end
  end

end
