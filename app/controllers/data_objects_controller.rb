class DataObjectsController < ApplicationController

  layout :data_objects_layout
  @@results_per_page = 20
  before_filter :check_authentication, :only => [:new, :create, :edit, :update, :ignore] # checks login only
  before_filter :load_data_object, :except => [:index, :new, :create ]
  before_filter :authentication_own_user_added_text_objects_only, :only => [:edit] # update handled separately
  before_filter :allow_login_then_submit, :only => [:rate]
  before_filter :curators_and_owners_only, :only => [:add_association, :remove_association]

  # GET /pages/:taxon_id/data_objects/new
  # We're only creating new user data objects in the context of a taxon concept so we need taxon_id to be provided in route
  def new
    @taxon_concept = TaxonConcept.find(params[:taxon_id])
    set_text_data_object_options
    @data_object = DataObject.new(:data_type => DataType.text,
                                  :license_id => License.cc.id,
                                  :language_id => current_language.id)
    # default to passed in toc param or brief summary if selectable, otherwise just the first selectable toc item
    selected_toc_item = @toc_items.select{|ti| ti.id == params[:toc].to_i}.first ||
                        @toc_items.select{|ti| ti == TocItem.brief_summary}.first ||
                        @toc_items[0]
    @selected_toc_item_id = selected_toc_item.id
    @page_title = I18n.t(:dato_new_text_for_taxon_page_title, :taxon => Sanitize.clean(@taxon_concept.title_canonical))
    @page_description = I18n.t(:dato_new_text_page_description)
    current_user.log_activity(:creating_new_data_object, :taxon_concept_id => @taxon_concept.id)
  end

  # POST /pages/:taxon_id/data_objects
  # We're only creating new user data objects in the context of a taxon concept so we need taxon_id to be provided in route
  def create
    @taxon_concept = TaxonConcept.find(params[:taxon_id])
    unless params[:data_object]
      create_failed
      return
    end

    @references = params[:references] # we'll need these if validation fails and we re-render new
    raise I18n.t(:dato_create_user_text_missing_user_exception) if current_user.nil?
    raise I18n.t(:dato_create_user_text_missing_taxon_id_exception) if @taxon_concept.blank?
    @data_object = DataObject.create_user_text(params[:data_object], :user => current_user,
                                               :taxon_concept => @taxon_concept, :toc_id => toc_id)

    if @data_object.nil? || @data_object.errors.any?
      @selected_toc_item_id = toc_id
      create_failed && return
    else
      add_references(@data_object)
      current_user.log_activity(:created_data_object_id, :value => @data_object.id,
                                :taxon_concept_id => @taxon_concept.id)
      # add this new object to the user's watch collection
      collection_item = CollectionItem.create(
        :object => @data_object,
        :collection => current_user.watch_collection
      )
      CollectionActivityLog.create(:collection => current_user.watch_collection, :user => current_user,
                                   :activity => Activity.collect, :collection_item => collection_item)
      @data_object.log_activity_in_solr(:keyword => 'create', :user => current_user, :taxon_concept => @taxon_concept)

      # Will try to redirect to the appropriate tab/section after adding text
      subchapter = @data_object.toc_items.first.label.downcase
      subchapter = 'literature' if subchapter == 'literature references'
      subchapter.gsub!(/ /, "_" )
      temp = ["education", "education_resources", "identification_resources", "nucleotide_sequences",
        "biomedical_terms", "citizen_science_links"] # to Resources tab
      if temp.include?(subchapter)
        return redirect_to education_taxon_resource_path(@taxon_concept,
                             :anchor => "data_object_#{@data_object.id}"), :status => :moved_permanently if
          ['education', 'education_resources'].include?(subchapter)
        return redirect_to identification_resources_taxon_resource_path(@taxon_concept,
                             :anchor => "data_object_#{@data_object.id}"), :status => :moved_permanently if
          subchapter == 'identification_resources'
        return redirect_to nucleotide_sequences_taxon_resource_path(@taxon_concept,
                             :anchor => "data_object_#{@data_object.id}"), :status => :moved_permanently if
          subchapter == 'nucleotide_sequences'
        return redirect_to biomedical_terms_taxon_resource_path(@taxon_concept,
                             :anchor => "data_object_#{@data_object.id}"), :status => :moved_permanently if
          subchapter == 'biomedical_terms'
        return redirect_to citizen_science_taxon_resource_path(@taxon_concept,
                             :anchor => "data_object_#{@data_object.id}"), :status => :moved_permanently if
          subchapter == 'citizen_science_links'
      elsif ["literature"].include?(subchapter)
        return redirect_to literature_taxon_literature_path(@taxon_concept,
                             :anchor => "data_object_#{@data_object.id}"), :status => :moved_permanently if
          subchapter == 'literature'
      end

      redirect_to taxon_details_path(@taxon_concept, :anchor => "data_object_#{@data_object.id}"), :status => :moved_permanently
    end
  end

  # GET /data_objects/:id/edit
  def edit
    # @data_object is loaded in before_filter :load_data_object
    set_text_data_object_options
    @selected_toc_item_id = @data_object.toc_items.first.id rescue nil
    @references = @data_object.visible_references.map {|r| r.full_reference}.join("\n\n")
    @page_title = I18n.t(:dato_edit_text_title)
    @page_description = I18n.t(:dato_edit_text_page_description)
  end

  # PUT /data_objects/:id
  # NOTE we don't actually edit the data object we create a new one and unpublish the old one.
  # old @data_object is loaded in before_filter :load_data_object
  def update
    @references = params[:references]
    if @data_object.users_data_object.user_id != current_user.id
      update_failed(I18n.t(:dato_update_users_text_not_owner_exception)) and return
    end
    old_cdohe_associations = @data_object.all_curated_data_objects_hierarchy_entries.dup
    # Note: replicate doesn't actually update, it creates a new data_object
    new_data_object = @data_object.replicate(params[:data_object], :user => current_user, :toc_id => toc_id)
    new_cdohe_associations = new_data_object.all_curated_data_objects_hierarchy_entries
    
    if new_data_object.nil?
      update_failed(I18n.t(:dato_update_user_text_error)) and return
    elsif new_data_object.errors.any?
      @data_object = new_data_object # We want to show the errors...
      update_failed(I18n.t(:dato_update_user_text_error)) and return
    else
      add_references(new_data_object)
      vetted_action = (current_user.min_curator_level?(:full) || current_user.is_admin?) ? :trusted : :unreviewed
      visibility_action = :show
      # Activity logs for auto vetted UDOs
      log_action(new_data_object.users_data_object, vetted_action) unless new_data_object.users_data_object.vetted_id == @data_object.users_data_object.vetted_id
      log_action(new_data_object.users_data_object, visibility_action) unless new_data_object.users_data_object.visibility_id == @data_object.users_data_object.visibility_id
      # Activity logs for auto vetted CDOHEs
      new_cdohe_associations.each do |cdohe|
        if old_cdohe = old_cdohe_associations.detect{|oca| oca if oca == cdohe}
          if old_cdohe
            log_action(cdohe, vetted_action) unless cdohe.vetted_id == old_cdohe.vetted_id
            log_action(cdohe, visibility_action) unless cdohe.visibility_id == old_cdohe.visibility_id
          end
        end
      end
      current_user.log_activity(:updated_data_object_id, :value => new_data_object.id,
                                :taxon_concept_id => new_data_object.taxon_concept_for_users_text.id)
      redirect_to data_object_path(new_data_object), :status => :moved_permanently
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
      current_user.log_activity(:rated_data_object_id, :value => @data_object.id)
    end

    respond_to do |format|
      if rated_successfully
        @data_object.update_solr_index
        flash[:notice] = I18n.t(:rating_added_notice)
      else
        # TODO: Ideally examine validation error and provide more informative error message.
        flash[:error] = I18n.t(:rating_not_added_error)
      end
      format.html { redirect_back_or_default }
      format.js do
        @current_user_ratings = logged_in? ? current_user.rating_for_object_guids([@data_object.guid]) : {}
        render :partial => 'rating', :locals => { :data_object => @data_object, :reload_ajax_rating => true,
          :minimal => params[:minimal] == 'true' ? true : false }
      end
    end

  end

  # GET /data_objects/:id
  def show
    @page_title = @data_object.best_title
    get_attribution
    @slim_container = true
    DataObject.preload_associations(@data_object,
      [ { :data_object_translation => { :original_data_object => :language } },
        { :translations => { :data_object => :language } },
        { :agents_data_objects => [ :agent, :agent_role ] },
        { :data_objects_hierarchy_entries => { :hierarchy_entry => [ :name, :taxon_concept, :vetted, :visibility ] } },
        { :curated_data_objects_hierarchy_entries => { :hierarchy_entry => [ :name, :taxon_concept, :vetted, :visibility ] } } ] )
    @revisions = @data_object.revisions_by_date
    @latest_published_revision = @data_object.latest_published_revision
    @translations = @data_object.available_translations_data_objects(current_user, nil)
    @translations.delete_if{ |t| t.language.nil? } unless @translations.nil?
    @image_source = get_image_source if @data_object.is_image?
    @current_user_ratings = logged_in? ? current_user.rating_for_object_guids([@data_object.guid]) : {}
    @page = params[:page]
    @activity_log = @data_object.activity_log(:ids => @revisions.collect{ |r| r.id }, :page => @page || nil)
    @rel_canonical_href = data_object_url(@data_object, :page => rel_canonical_href_page_number(@activity_log))
    @rel_prev_href = rel_prev_href_params(@activity_log) ? data_object_url(@rel_prev_href_params) : nil
    @rel_next_href = rel_next_href_params(@activity_log) ? data_object_url(@rel_next_href_params) : nil
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
  # This is a GET, so there's no real reason to check to see whether or not the current_user can curate the object -
  # we leave that to the #curate method
  #
  def curation
  end

  def remove_association
    he = HierarchyEntry.find(params[:hierarchy_entry_id])
    @data_object.remove_curated_association(current_user, he)
    clear_cached_media_count_and_exemplar(he)
    @data_object.update_solr_index
    log_action(he, :remove_association, :taxon_concept_id => he.taxon_concept_id)
    redirect_to data_object_path(@data_object), :status => :moved_permanently
  end

  def save_association
    he = HierarchyEntry.find(params[:hierarchy_entry_id])
    @data_object.add_curated_association(current_user, he)
    clear_cached_media_count_and_exemplar(he)
    @data_object.update_solr_index
    log_action(he, :add_association)
    redirect_to data_object_path(@data_object), :status => :moved_permanently
  end

  def add_association
    @querystring = params[:name]
    if @querystring.blank?
      @all_results = empty_paginated_set
    else
      search_response = EOL::Solr::SiteSearch.search_with_pagination(@querystring, params.merge({ :type => ['taxon_concept'], :per_page => @@results_per_page }))
      @all_results = search_response[:results]
      unless @all_results.blank?
        @all_results.each do |result|
          browsable_entries = []
          unbrowsable_entries = []
          result_instance = result['instance']
          hierarchy_entries = result_instance.published_hierarchy_entries.blank? ? result_instance.hierarchy_entries : result_instance.published_hierarchy_entries
          hierarchy_entries.each do |hierarchy_entry|
            hierarchy_entry.hierarchy.browsable? ? browsable_entries << hierarchy_entry : unbrowsable_entries << hierarchy_entry
          end
          result_instance['entries'] = browsable_entries.blank? ? unbrowsable_entries : browsable_entries
        end
      end
      params.delete(:commit) unless params[:commit].blank?
      @all_results
    end
  end

  def curate_associations
    if current_user.min_curator_level?(:full)
      return_to = params[:return_to] unless params[:return_to].blank?
      store_location(return_to)
      begin
        entries = []
        entries = @data_object.all_associations

        entries.each do |phe|
          comment = curation_comment(params["curation_comment_#{phe.id}"])
          vetted_id = params["vetted_id_#{phe.id}"].to_i

          # make visibility hidden if curated as Inappropriate or Untrusted
          visibility_id = (vetted_id == Vetted.inappropriate.id || vetted_id == Vetted.untrusted.id) ? Visibility.invisible.id : params["visibility_id_#{phe.id}"].to_i

          # check if the visibility has been changed
          visibility_changed = visibility_id.blank? ? false : (phe.visibility_id != visibility_id)

          # explicitly mark visibility as changed if it is already hidden and marked as trusted or unreviewed from untrusted.
          # this is required as we don't ask for hide reasons while marking an association as untrusted
          # if we don't do this, code will grab the last hide reason for that association if it was marked as hidden in the past.
          # if you are here to refactor the code(and about to remove the following line) then please make sure the hiding of the association works properly
          visibility_changed = (phe.visibility_id == Visibility.invisible.id && (vetted_id == Vetted.trusted.id || vetted_id == Vetted.unknown.id)) ? true : false unless visibility_changed == true
          all_params = { :vetted_id => vetted_id,
                         :visibility_id => visibility_id,
                         :curation_comment => comment,
                         :untrust_reason_ids => params["untrust_reasons_#{phe.id}"],
                         :hide_reason_ids => params["hide_reasons_#{phe.id}"],
                         :untrust_reasons_comment => params["untrust_reasons_comment_#{phe.id}"],
                         :vet? => vetted_id.blank? ? false : (phe.vetted_id != vetted_id),
                         :visibility? => visibility_changed,
                         :comment? => !comment.nil?,
                       }
          curate_association(current_user, phe, all_params)
        end
        @data_object.reload # This reload is necessary. Please do not remove.
        @data_object.update_solr_index
      rescue => e
        flash[:error] = e.message
      end
    else
      access_denied
    end
    redirect_back_or_default data_object_path(@data_object.latest_published_revision)
  end

  def ignore
    return_to = params[:return_to] unless params[:return_to].blank?
    store_location(return_to)
    if params[:undo]
      WorklistIgnoredDataObject.destroy_all("user_id = #{current_user.id} AND data_object_id = #{@data_object.id}")
    else
      @data_object.worklist_ignored_data_objects << WorklistIgnoredDataObject.create(:user => current_user, :data_object => @data_object)
    end
    @data_object.update_solr_index
    redirect_back_or_default
  end

protected

  def scoped_variables_for_translations
    return @scoped_variables_for_translations unless @scoped_variables_for_translations.nil?
    if (@data_object && @data_object.added_by_user? && !@data_object.users_data_object.blank?)
      supplier = @data_object.users_data_object.user.full_name rescue nil
    elsif (@data_object && @data_object.content_partner)
      supplier = @data_object.content_partner.name
    else
      supplier = I18n.t('data_objects.show.meta_supplier_default')
    end
    @scoped_variables_for_translations = super.dup.merge({
      :dato_title => @data_object ? @data_object.best_title.presence : nil,
      :dato_description => @data_object ? @data_object.description.presence : nil,
      :supplier => supplier,
    }).freeze
  end

  def meta_description
    return @meta_description if defined?(@meta_description)
    i18n_key = 'meta_description'
    @meta_description = t(".#{i18n_key}", scoped_variables_for_translations.dup)
    if @data_object && @meta_description.blank?
      en_type = ApplicationHelper.en_type(@data_object)
      i18n_key << '_default' unless @data_object.description.presence
      i18n_key << "_#{en_type}" unless en_type.nil?
      @meta_description = t(".#{i18n_key}", scoped_variables_for_translations.dup)
    end
    @meta_description
  end

  def meta_open_graph_image_url
    @meta_open_graph_image_url ||= @data_object ?
      @data_object.thumb_or_object('260_190', $SINGLE_DOMAIN_CONTENT_SERVER).presence : nil
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
    when 'add_association'
      'v2/association'
    else
      'v2/data'
    end
  end

  def curators_and_owners_only
    unless current_user.min_curator_level?(:assistant) || current_user == @data_object.user
      access_denied
    end
  end

  def authentication_own_user_added_text_objects_only
    if !@data_object.is_text? || @data_object.users_data_object.blank? ||
       @data_object.user.id != current_user.id
      access_denied
    end
  end

  def curation_comment(comment)
    commented = !comment.blank? # TODO - what is commented variable for?
    if comment.blank?
      return nil
    else
      auto_collect(@data_object) # SPG asks for all curation comments to add the item to their watchlist.
      # TODO - we really don't need this from_curator flag now:
      return Comment.create(:parent => @data_object, :body => comment, :user => current_user, :from_curator => true)
    end
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

  def create_failed
    if params[:data_object]
      flash.now[:error] = I18n.t(:dato_create_user_text_error)
      set_text_data_object_options
      @page_title = I18n.t(:dato_new_text_for_taxon_page_title,
                           :taxon => Sanitize.clean(@taxon_concept.title_canonical))
      @page_description = I18n.t(:dato_new_text_page_description)
      render :action => 'new', :layout => 'v2/basic'
    else
      flash[:error] = I18n.t(:dato_create_user_text_error)
      redirect_to new_taxon_data_object_path(@taxon_concept)
    end
  end

  def update_failed(err)
    flash[:error] = err
    if params[:data_object]
      # We have new data object values so we re-render edit form with an error message.
      set_text_data_object_options
      @selected_toc_item_id = toc_id
      @page_title = I18n.t(:dato_edit_text_title)
      @page_description = I18n.t(:dato_edit_text_page_description)
      # Be kind, rewind:
      @data_object.attributes = params[:data_object] # Sets them, doesn't save them.
      render :action => 'edit', :layout => 'v2/basic'
    else
      # Someone PUT directly to /data_objects/NNN with no params.  (Which is... weird.  But hey.)
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
      curated_object = get_curated_object(hierarchy_entry)
      return if curated_object.visibility_id == Visibility.preview.id
      handle_curation(curated_object, user, opts).each do |action|
        log = log_action(curated_object, action)
        # Saves untrust reasons, if any
        unless opts[:untrust_reason_ids].blank?
          save_untrust_reasons(log, action, opts[:untrust_reason_ids])
        end
        unless opts[:hide_reason_ids].blank?
          save_hide_reasons(log, action, opts[:hide_reason_ids])
        end
        clear_cached_media_count_and_exemplar(hierarchy_entry) if action == :hide
      end
    end
  end

  def something_needs_curation?(opts)
    opts[:vet?] || opts[:visibility?]
  end

  def get_curated_object(hierarchy_entry)
    if hierarchy_entry.class == UsersDataObject
      curated_object = UsersDataObject.find_by_data_object_id(@data_object.latest_published_revision.id)
    elsif hierarchy_entry.associated_by_curator
      curated_object = CuratedDataObjectsHierarchyEntry.find_by_data_object_guid_and_hierarchy_entry_id(@data_object.guid, hierarchy_entry.id)
    else
      curated_object = DataObjectsHierarchyEntry.find_by_data_object_id_and_hierarchy_entry_id(@data_object.latest_published_revision.id, hierarchy_entry.id)
    end
  end

  # Figures out exactly what kind of curation is occuring, and performs it.  Returns an *array* of symbols
  # representing the actions that were taken.  ...which you may want to log.  :)
  def handle_curation(object, user, opts)
    actions = []
    raise "Curator should supply at least visibility or vetted information" unless (opts[:vet?] || opts[:visibility?])
    actions << handle_vetting(object, opts[:vetted_id].to_i, opts[:visibility_id].to_i, opts) if opts[:vet?]
    actions << handle_visibility(object, opts[:vetted_id].to_i, opts[:visibility_id].to_i, opts) if opts[:visibility?]
    return actions.flatten
  end

  def handle_vetting(object, vetted_id, visibility_id, opts)
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
        if visibility_id == Visibility.invisible.id && opts[:hide_reason_ids].blank? && opts[:curation_comment].nil?
          raise "Curator should supply at least reason(s) to hide and/or curation comment"
        end
        object.trust(current_user)
        return :trusted
      when Vetted.unknown.id
        if visibility_id == Visibility.invisible.id && opts[:hide_reason_ids].blank? && opts[:curation_comment].nil?
          raise "Curator should supply at least reason(s) to hide and/or curation comment"
        end
        object.unreviewed(current_user)
        return :unreviewed
      else
        raise "Cannot set data object vetted id to #{vetted_id}"
      end
    end
  end

  def handle_visibility(object, vetted_id, visibility_id, opts)
    if visibility_id
      changeable_object_type = opts[:changeable_object_type]
      case visibility_id
      when Visibility.visible.id
        object.show(current_user)
        return :show
      when Visibility.invisible.id
        if vetted_id != Vetted.untrusted.id && opts[:hide_reason_ids].blank? && opts[:curation_comment].nil?
          raise "Curator should supply at least reason(s) to hide and/or curation comment"
        end
        object.hide(current_user)
        return :hide
      else
        raise "Cannot set data object visibility id to #{visibility_id}"
      end
    end
  end

  def log_action(object, method, opts = {})
    object_id = object.data_object_id if object.class.name == "DataObjectsHierarchyEntry" || object.class.name == "CuratedDataObjectsHierarchyEntry" || object.class.name == "UsersDataObject"
    object_id = object.id if object_id.blank?

    if object.class.name == "DataObjectsHierarchyEntry" || object.class.name == "CuratedDataObjectsHierarchyEntry"
      he = object.hierarchy_entry
    elsif object.class.name == "HierarchyEntry"
      he = object
    end

    if method == :add_association || method == :remove_association
      changeable_object_type = ChangeableObjectType.send("CuratedDataObjectsHierarchyEntry".underscore.to_sym)
    else
      changeable_object_type = ChangeableObjectType.send(object.class.name.underscore.to_sym)
    end

    flash[:notice] ||= ''
    flash[:notice]  += ' ' + I18n.t(:object_curated)
    auto_collect(@data_object) # SPG asks for all curation to add the item to their watchlist.
    create_options = {
      :user => current_user,
      :changeable_object_type => changeable_object_type,
      :object_id => object_id,
      :activity => Activity.send(method),
      :data_object => @data_object,
      :data_object_guid => @data_object.guid,
      :hierarchy_entry => he,
      :created_at => 0.seconds.from_now
    }
    if object.class.name == "UsersDataObject"
      create_options.merge!(:taxon_concept_id => object.taxon_concept_id)
    end
    CuratorActivityLog.create(create_options)
  end

  def save_untrust_reasons(log, action, untrust_reason_ids)
    untrust_reason_ids.each do |untrust_reason_id|
      case untrust_reason_id.to_i
      when UntrustReason.misidentified.id
        log.untrust_reasons << UntrustReason.misidentified if action == :untrusted
      when UntrustReason.incorrect.id
        log.untrust_reasons << UntrustReason.incorrect if action == :untrusted
      else
        raise "Please re-check the provided untrust reasons"
      end
    end
  end

  def save_hide_reasons(log, action, hide_reason_ids)
    hide_reason_ids.each do |hide_reason_id|
      case hide_reason_id.to_i
      when UntrustReason.poor.id
        log.untrust_reasons << UntrustReason.poor if action == :hide
      when UntrustReason.duplicate.id
        log.untrust_reasons << UntrustReason.duplicate if action == :hide
      else
        raise "Please re-check the provided hide reasons"
      end
    end
  end

  def empty_paginated_set
    [].paginate(:page => 1, :per_page => @@results_per_page, :total_entries => 0)
  end

  def clear_cached_media_count_and_exemplar(he)
    if $CACHE
      tc = he.taxon_concept
      if @data_object.data_type.label == 'Image'

        txei_exists = TaxonConceptExemplarImage.find_by_taxon_concept_id_and_data_object_id(tc.id, @data_object.id)
        txei_exists.destroy unless txei_exists.nil?

        cached_taxon_exemplar = Rails.cache.fetch(TaxonConcept.cached_name_for("best_image_#{tc.id}"))
        unless cached_taxon_exemplar.nil? || cached_taxon_exemplar == "none"
          Rails.cache.delete(TaxonConcept.cached_name_for("best_image_#{tc.id}")) if cached_taxon_exemplar.guid == @data_object.guid
        end
        Rails.cache.delete(TaxonConcept.cached_name_for("media_count_#{tc.id}_curator"))
        Rails.cache.delete(TaxonConcept.cached_name_for("media_count_#{tc.id}"))

        tc.published_browsable_hierarchy_entries.each do |pbhe|
          cached_taxon_he_exemplar = Rails.cache.fetch(TaxonConcept.cached_name_for("best_image_#{tc.id}_#{pbhe.id}"))
          unless cached_taxon_he_exemplar.nil? || cached_taxon_he_exemplar == "none"
            Rails.cache.delete(TaxonConcept.cached_name_for("best_image_#{tc.id}_#{pbhe.id}")) if cached_taxon_he_exemplar.guid == @data_object.guid
          end
          Rails.cache.delete(TaxonConcept.cached_name_for("media_count_#{tc.id}_#{pbhe.id}_curator"))
          Rails.cache.delete(TaxonConcept.cached_name_for("media_count_#{tc.id}_#{pbhe.id}"))
        end
      end
    end
  end

  def add_references(dato)
    return if params[:references].blank?
    references = params[:references].split("\n")
    unless references.blank?
      references.each do |reference|
        if reference.strip != ''
          dato.refs << Ref.new(:full_reference => reference, :user_submitted => true, :published => 1,
                                       :visibility => Visibility.visible)
        end
      end
    end
  end

  def toc_id
    @ti ||= params[:data_object].delete(:toc_items)[:id].to_a
    @ti.empty? ? nil : @ti.first.to_i
  end

end
