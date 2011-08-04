class DataObjectsController < ApplicationController

  layout :data_objects_layout

  before_filter :check_authentication, :only => [:new, :create, :edit, :update] # checks login only
  before_filter :load_data_object, :except => [:index, :new, :create, :preview]
  before_filter :authentication_own_user_added_text_objects_only, :only => [:edit, :update]
  before_filter :allow_login_then_submit, :only => [:rate]
  before_filter :curator_only, :only => [:curate, :add_association, :remove_association]

  # GET /pages/:taxon_id/data_objects/new
  # We're only creating new data objects in the context of a taxon concept so we for taxon_id to be provided in route
  def new
    @taxon_concept = TaxonConcept.find(params[:taxon_id])
    set_text_data_object_options
    @data_object = DataObject.new(:data_type => DataType.text,
                                  :license_id => License.by_nc.id,
                                  :language_id => current_user.language_id)
    # default to brief summary if selectable otherwise just the first toc item
    @selected_toc_item = @toc_items.select{|ti| ti == TocItem.brief_summary}.first || @toc_items[0]
    @page_title = I18n.t(:dato_new_text_for_taxon_page_title, :taxon => Sanitize.clean(@taxon_concept.title_canonical))
    @page_description = I18n.t(:dato_new_text_page_description)
    current_user.log_activity(:creating_new_data_object, :taxon_concept_id => @taxon_concept.id)
  end

  # POST /pages/:taxon_id/data_objects
  def create
    @taxon_concept = TaxonConcept.find(params[:taxon_id])
    return failed_to_create_data_object unless params[:data_object]

    @references = params[:references] # we'll need these if validation fails and we re-render new
    params[:references] = params[:references].split("\n") unless params[:references].blank?
    @data_object = DataObject.create_user_text(params, current_user, @taxon_concept)
    @selected_toc_item = @data_object.toc_items.first unless @data_object.nil?

    if @data_object.nil? || @data_object.errors.any?
      failed_to_create_data_object and return
    else
      # TODO: alter_current_user is to allow the current user to see the text object they just added,
      # if their preferences were set to vetted, however - the preference of seeing only
      # vetted may now be obsolete. I'm leaving this here for now, but maybe we can remove.
      alter_current_user do |user|
        user.vetted=false
      end
      current_user.log_activity(:created_data_object_id, :value => @data_object.id,
                                :taxon_concept_id => @taxon_concept.id)
      redirect_to taxon_details_path(@taxon_concept, :anchor => "data_object_#{@data_object.id}")
    end
  end

  # GET /data_objects/:id/edit
  def edit
    # @data_object is loaded in before_filter
    set_text_data_object_options
    @selected_toc_item = @data_object.toc_items[0]
    @references = @data_object.visible_references.map {|r| r.full_reference}.join("\n\n")
    @page_title = I18n.t(:dato_edit_text_title)
    @page_description = I18n.t(:dato_edit_text_page_description)
  end

  # PUT /data_objects/:id
  def update
    # old @data_object is loaded in before_filter
    return failed_to_update_data_object unless params[:data_object]
    @references = params[:references]
    params[:references] = params[:references].split("\n")
    # Note: update_user_text doesn't actually update, it creates a new data_object
    @data_object = DataObject.update_user_text(params, current_user)
    @selected_toc_item = @data_object.toc_items.first unless @data_object.nil?

    if @data_object.nil? || @data_object.errors.any?
      # TODO: this is unpleasant, we are using update to create a new data object so @data_object.new_record?
      # is now true. The edit action expects a data_object id, but we need the new values.
      failed_to_update_data_object and return
    else
      # TODO: alter_current_user is to allow the current user to see the text object they just added,
      # if their preferences were set to vetted, however - the preference of seeing only
      # vetted may now be obsolete. I'm leaving this here for now, but maybe we can remove.
      alter_current_user do |user|
        user.vetted = false
      end
      current_user.log_activity(:updated_data_object_id, :value => @data_object.id,
                                :taxon_concept_id => @data_object.taxon_concept_for_users_text.id)
      redirect_to data_object_path(@data_object)
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

  # GET /data_objects/:id
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
    log_action(he, :remove_association, nil)
    redirect_to data_object_path(@data_object)
  end

  def save_association
    he = HierarchyEntry.find(params[:hierarchy_entry_id])
    @data_object.add_curated_association(current_user, he)
    log_action(he, :add_association, nil)
    redirect_to data_object_path(@data_object)
  end

  def add_association
    name = params[:name]
    form_submitted = params[:commit]
    unless form_submitted.blank?
      unless name.blank?
        entries_for_name(name)
      else
        flash[:error] = I18n.t(:please_enter_a_name_to_find_taxa)
      end
    end
  end

  def curate_associations
    raise EOL::Exceptions::Pending
    begin
      @data_object.published_entries.each do |phe|
        comment = curation_comment(params["curation_comment_#{phe.id}"])
        vetted_id = params["vetted_id_#{phe.id}"].to_i
        # make visibility hidden if curated as Inappropriate or Untrusted
        visibility_id = (vetted_id == Vetted.inappropriate.id || vetted_id == Vetted.untrusted.id) ? Visibility.invisible.id : params["visibility_id_#{phe.id}"].to_i
        all_params = { :vetted_id => vetted_id,
                       :visibility_id => visibility_id,
                       :curation_comment => comment,
                       :untrust_reason_ids => params["untrust_reasons_#{phe.id}"],
                       :untrust_reasons_comment => params["untrust_reasons_comment_#{phe.id}"],
                       :vet? => (vetted_id == 0) ? false : (phe.vetted_id != vetted_id),
                       :visibility? => (visibility_id == 0) ? false : (phe.visibility_id != visibility_id),
                       :comment? => !comment.nil?,
                     }
        curate_association(current_user, phe, all_params)
      end
    rescue => e
      flash[:error] = e.message
    end
    redirect_to data_object_path(@data_object)
  end

  # NOTE - It seems like this is a HEAVY controller... and perhaps it is.  But I can't think of *truly* appropriate
  # places to put the following code for handling curation and the logging thereof.
private

  def data_objects_layout
    # No layout for Ajax calls.
    return false if request.xhr?
    case action_name
    when 'new', 'create', 'update', 'edit'
      'v2/basic'
    else
      'v2/data'
    end
  end

  def curator_only
    unless current_user.is_curator?
      access_denied
    end
  end

  def authentication_own_user_added_text_objects_only
    if !@data_object.is_text? || @data_object.users_data_objects.blank? ||
       @data_object.user.id != current_user.id
      access_denied
    end
  end

  def curation_comment(comment)
    commented = !comment.blank? # TODO - what is commented variable for?
    if comment.blank?
      return nil
    else
      # TODO - we really don't need this from_curator flag now:
      return Comment.create(:parent => @data_object, :body => comment, :user => current_user, :from_curator => true)
    end
  end

  def entries_for_name(name)
    browsable_entries = []
    unbrowsable_entries = []
    search_response = EOL::Solr::SiteSearch.search_with_pagination(name, :type => ['taxon_concept'])
    unless search_response[:results].blank?
      search_response[:results].each do |result|
        result_instance = result['instance']
        if result_instance.class == TaxonConcept
          hierarchy_entries = result_instance.published_hierarchy_entries.blank? ? result_instance.hierarchy_entries : result_instance.published_hierarchy_entries
          hierarchy_entries.each do |hierarchy_entry|
            hierarchy_entry.hierarchy.browsable? ? browsable_entries << hierarchy_entry : unbrowsable_entries << hierarchy_entry
          end
        end
      end
    end
    @entries = browsable_entries.blank? ? unbrowsable_entries : browsable_entries
  end

  def load_data_object
    @data_object ||= DataObject.find(params[:id])
  end

  def get_attribution
    current_user.log_activity(:showed_attributions_for_data_object_id, :value => @data_object.id)
  end

  def set_text_data_object_options
    @toc_items = TocItem.selectable_toc
    @languages = Language.find_by_sql("SELECT * FROM languages WHERE iso_639_1 != '' && source_form != ''")
    @licenses = License.find_all_by_show_to_content_partners(1)
  end

  def failed_to_create_data_object
    if params[:data_object]
      flash.now[:error] = I18n.t(:dato_create_user_text_error)
      set_text_data_object_options
      @page_title = I18n.t(:dato_new_text_for_taxon_page_title, :taxon => Sanitize.clean(@taxon_concept.title_canonical))
      @page_description = I18n.t(:dato_new_text_page_description)
      render :action => 'new', :layout => 'v2/basic'
    else
      flash[:error] = I18n.t(:dato_create_user_text_error)
      redirect_to new_taxon_data_object_path(@taxon_concept)
    end
  end

  def failed_to_update_data_object
    if params[:data_object]
      flash.now[:error] = I18n.t(:dato_update_user_text_error)
      set_text_data_object_options
      @page_title = I18n.t(:dato_edit_text_title)
      @page_description = I18n.t(:dato_edit_text_page_description)
      render :action => 'edit', :layout => 'v2/basic'
    else
      flash[:error] = I18n.t(:dato_update_user_text_error)
      redirect_to edit_data_object_path(@data_object)
    end
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
    if something_needs_curation?(opts)
      curated_object = get_curated_object(@data_object, hierarchy_entry)
      handle_curation(curated_object, user, opts).each do |action|
        log = log_action(curated_object, action, opts)
        # Saves untrust reasons, if any
        unless opts['untrust_reason_ids'].blank?
          save_untrust_reasons(log, action, opts['untrust_reason_ids'])
        end
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
    raise "Curator should supply at least visibility or vetted information" unless (opts[:vet?] || opts[:visibility?])
    actions << handle_vetting(object, opts[:vetted_id].to_i, opts) if opts[:vet?]
    actions << handle_visibility(object, opts[:visibility_id].to_i, opts) if opts[:visibility?]
    return actions.flatten
  end

  def handle_vetting(object, vetted_id, opts)
    if vetted_id
      case vetted_id
      when Vetted.inappropriate.id
        object.inappropriate(current_user)
        return :inappropriate
      when Vetted.untrusted.id
        raise "Curator should supply at least untrust reason(s) and/or curation comment" if (opts[:untrust_reason_ids].blank? && opts[:curation_comment].nil?)
        object.untrust(current_user)
        return :untrusted
      when Vetted.trusted.id
        object.trust(current_user)
        return :trusted
      when Vetted.unknown.id
        object.unreviewed(current_user)
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
      when Visibility.visible.id
        object.show(current_user)
        return :show
      when Visibility.invisible.id
        raise "Curator should supply at least reason(s) to hide and/or curation comment" if (opts[:untrust_reason_ids].blank? && opts[:curation_comment].nil?)
        # TODO - when I tried this, it actually removed the association entirely.
        object.hide(current_user)
        return :hide
      else
        raise "Cannot set data object visibility id to #{visibility_id}"
      end
    end
  end

  # TODO - Remove the opts parameter if we not intend to use it.
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

  def save_untrust_reasons(log, action, untrust_reason_ids)
    untrust_reason_ids.each do |untrust_reason_id|
      case untrust_reason_id.to_i
      when UntrustReason.misidentified.id
        log.untrust_reasons << UntrustReason.misidentified if action == :untrusted
      when UntrustReason.incorrect.id
        log.untrust_reasons << UntrustReason.incorrect if action == :untrusted
      when UntrustReason.poor.id
        log.untrust_reasons << UntrustReason.poor if action == :hide
      when UntrustReason.duplicate.id
        log.untrust_reasons << UntrustReason.duplicate if action == :hide
      else
        raise "Please re-check the provided untrust reasons"
      end
    end
  end

end
