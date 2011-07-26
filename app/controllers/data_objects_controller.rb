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
    #render(:partial => '/taxa/text_data_object',
    #render(:partial => '/taxa/details/category_content',
    #       :locals => {:content => data_object, :comments_style => '', :category => data_object.toc_items[0].label})
    redirect_to taxon_details_path(@taxon_concept)
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
    #render(:partial => '/taxa/text_data_object', :locals => {:content_item => @data_object, :comments_style => '', :category => @data_object.toc_items[0].label})
    render(:partial => '/taxa/details/category_content_part', :locals => {:dato => @data_object, :with_javascript => 1})
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

  def rate
    rated_successfully = false
    stars = params[:stars] unless params[:stars].blank?
    return_to = params[:return_to] unless params[:return_to].blank?

    if session[:submitted_data]
      stars ||= session[:submitted_data][:stars]
      return_to ||= session[:submitted_data][:return_to]
      session.delete(:submitted_data)
    end

    store_location(return_to)

    if stars.to_i > 0
      rated_successfully = @data_object.rate(current_user, stars.to_i)
      expire_data_object(@data_object.id)
      current_user.log_activity(:rated_data_object_id, :value => @data_object.id)
    end

    respond_to do |format|
      if rated_successfully
        flash[:notice] = I18n.t(:rating_added_notice)
      else
        # TODO: Ideally examine validation error and provide more informative error message.
        flash[:error] = I18n.t(:rating_not_added_error)
      end
      format.html { redirect_back_or_default }
      # format.js {render :action => 'rate.rjs'} #TODO
    end

  end

  def show
    @page_title = @data_object.best_title
    get_attribution
    @comments = @data_object.all_comments.dup.paginate(:page => params[:page], :order => 'updated_at DESC', :per_page => Comment.per_page)
    @slim_container = true
    @revisions = @data_object.revisions.sort_by(&:created_at).reverse
    @translations = @data_object.available_translations_data_objects(current_user)
    @taxon_concepts = @data_object.get_taxon_concepts(:published => :preferred)
    @scientific_names = @taxon_concepts.inject({}) { |res, tc| res[tc.scientific_name] = { :common_name => tc.common_name, :taxon_concept_id => tc.id }; res }
    @image_source = get_image_source if @data_object.is_image?
    @current_user_ratings = logged_in? ? current_user.rating_for_object_guids([@data_object.guid]) : {}
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
    he = HierarchyEntry.find(params[:hierarchy_entry_id])
    @data_object.remove_curated_association(current_user, he)
    log_action(@entries.first, :add_association)
    redirect_to data_object_path(@data_object)
  end

  def add_association
    @name = params[:name]
    form_submitted = params[:commit]
    unless form_submitted.blank?
      unless @name.blank?
        # TODO - use solr search for finding the taxa
        @entries = entries_for_name(@name)
      else
        debugger
        flash[:error] = I18n.t(:please_enter_a_name_to_find_taxa)
      end
    end
    # if @entries.length == 1
    #   @data_object.add_curated_association(current_user, @entries.first)
    #   redirect_to data_object_path(@data_object)
    #   log_action(@entries.first, :add_association)
    # end
  end

  def curate_associations
    @data_object.published_entries.each do |phe|
      comment = curation_comment(params["curation_comment_#{phe.id}"])
      all_params = { :vetted_id => params["vetted_id_#{phe.id}"],
                     :visibility_id => params["visibility_id_#{phe.id}"],
                     :curation_comment => comment,
                     :untrust_reason_ids => params["untrust_reasons_#{phe.id}"],
                     :untrust_reasons_comment => params["untrust_reasons_comment_#{phe.id}"],
                     :vet? => phe.vetted_id != params["vetted_id_#{phe.id}"].to_i,
                     :visibility? => phe.visibility_id != params["visibility_id_#{phe.id}"].to_i,
                     :comment? => !comment.nil?,
                   }
      curate_association(current_user, phe, all_params)
    end
    redirect_to data_object_path(@data_object)
  end

  # NOTE - It seems like this is a HEAVY controller... and perhaps it is.  But I can't think of *truly* appropriate
  # places to put the following code for handling curation and the logging thereof.
private

  def curator_only
    if !current_user.can_curate?(@data_object)
      raise Exception.new('Not logged in as curator')
    end
  end

  def curation_comment(comment)
    commented = !comment.blank?
    if comment.blank?
      return nil
    else
      # TODO - we really don't need this from_curator flag now:
      return Comment.create(:parent => @data_object, :body => comment, :user => current_user, :from_curator => true)
    end
  end

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
      @data_object.thumb_or_object('580_360')
    end
  end

  # Aborts if nothing changed. Otherwise, decides what to curate, handles that, and logs the changes:
  def curate_association(user, hierarchy_entry, opts)
    debugger
    if something_needs_curation?(opts)
      curated_object = get_curated_object(@data_object, hierarchy_entry)
      handle_curation(curated_object, user, opts).each do |action|
        log = log_action(curated_object, action, opts)
        # TODO - Untrust reasons, if any, must be added here.
      end
      # TODO - Update Solr Index
    end
  end

  def something_needs_curation?(opts)
    opts[:vet?] || opts[:visibility?]
  end

  def get_curated_object(dato, he)
    if he.associated_by_curator
      curated_object = CuratedDataObjectsHierarchyEntry.find_by_data_object_id_and_hierarchy_entry_id(dato.id, he.id)
    else
      curated_object = DataObjectsHierarchyEntry.find_by_data_object_id_and_hierarchy_entry_id(dato.id, he.id)
    end
    return curated_object
  end

  # Figures out exactly what kind of curation is occuring, and performs it.  Returns an *array* of symbols
  # representing the actions that were taken.  ...which you may want to log.  :)
  def handle_curation(object, user, opts)
    actions = []
    raise "Curator should supply at least visibility or vetted information" unless (vetted_id || visibility_id)
    actions << handle_vetting(object, opts[:vetted_id].to_i, opts) if opts[:vet?]
    actions << handle_visibility(object, opts[:visibility_id].to_i, opts) if opts[:visibility?]
    return actions.flatten
  end

  def handle_vetting(object, vetted_id, opts)
    if vetted_id
      case vetted_id
      when Vetted.inappropriate.id
        object.inappropriate(user, opts)
        return :inappropriate
      when Vetted.untrusted.id
        raise "Curator should supply at least untrust reason(s) and/or curation comment" if (opts[:untrust_reason_ids].blank? && opts[:curation_comment].nil?)
        object.untrust(user, opts)
        return :untrusted
      when Vetted.trusted.id
        object.trust(user, opts)
        return :trusted
      when Vetted.unknown.id
        object.unreviewed(user, opts)
        return :unreviewed
      else
        raise "Cannot set data object vetted id to #{vetted_id}"
      end
    end
  end

  def handle_visibility(object, visibility_id, opts)
    if visibility_id
      changeable_object_type = opts[:changeable_object_type]
      case visibility_id
      when Visibility.visible.id.flatten
        object.show(user, opts[:type], changeable_object_type)
        return :show
      when Visibility.invisible.id
        object.hide(user, opts[:type], changeable_object_type)
        return :hide
      else
        raise "Cannot set data object visibility id to #{visibility_id}"
      end
    end
  end

  def log_action(object, method, opts)
    CuratorActivityLog.create(
      :user => current_user,
      :changeable_object_type => ChangeableObjectType.send(object.class.name.underscore.to_sym),
      :object_id => object.id,
      :activity => Activity.send(method),
      :data_object => @data_object,
      :created_at => 0.seconds.from_now
    )
  end

end
