class DataObjectsController < ApplicationController

  layout :data_objects_layout
  @@results_per_page = 20

  before_filter :check_authentication, only: [:new, :create, :edit, :update, :ignore, :crop, :reindex, :explain] # checks login only
  before_filter :load_data_object, except: [:index, :new, :create ]
  before_filter :authentication_own_user_added_text_objects_only, only: [:edit] # update handled separately
  before_filter :allow_login_then_submit, only: [:rate]
  before_filter :curators_and_owners_only, only: [:add_association, :remove_association]
  before_filter :restrict_to_admins_and_curators, only: [:crop, :explain]
  before_filter :restrict_to_admins_and_master_curators, only: [:reindex]

  # GET /data_objects/new
  # requires a taxon_id as a parameter.
  # We're only creating new user data objects in the context of a taxon concept so we need taxon_id to be provided in route
  def new
    @taxon_concept = TaxonConcept.find(params[:taxon_id])
    set_text_data_object_options
    @data_object ||= DataObject.new(data_type: DataType.text,
                                  license_id: License.cc.id,
                                  object_created_at: Time.now,
                                  object_modified_at: Time.now,
                                  language_id: current_language.id)
    unless params[:data_object]
      # default to passed in toc param or brief summary if selectable, otherwise just the first selectable toc item
      selected_toc_item = @toc_items.select { |ti| ti.id == params[:toc].to_i }.first ||
                          @toc_items.select { |ti| ti == TocItem.brief_summary }.first ||
                          @toc_items[0]
      @selected_toc_item_id = selected_toc_item.id
    end
    if params[:link] || params[:commit_link]
      @add_link = true
      @page_title = I18n.t(:dato_new_text_link_for_taxon_page_title, taxon: Sanitize.clean(@taxon_concept.title_canonical))
    else
      @add_article = true
      @page_title = I18n.t(:dato_new_text_for_taxon_page_title, taxon: Sanitize.clean(@taxon_concept.title_canonical))
    end
    @page_description = I18n.t(:dato_new_text_page_description)
    render :new
  end

  # POST /pages/:taxon_id/data_objects
  # We're only creating new user data objects in the context of a taxon concept so we need taxon_id to be provided in route
  def create
    @taxon_concept = TaxonConcept.find(params[:taxon_id])
    unless params[:data_object] && params[:data_object][:data_type_id].to_i == DataType.text.id
      create_failed
      return
    end

    @references = params[:references] # we'll need these if validation fails and we re-render new
    raise I18n.t(:dato_create_user_text_missing_user_exception) if current_user.nil?
    raise I18n.t(:dato_create_user_text_missing_taxon_id_exception) if @taxon_concept.blank?
    if DataObject.same_as_last?(params, user: current_user,taxon_concept: @taxon_concept )
      flash[:notice] = I18n.t(:duplicate_text_warning)
      self.new && return
    elsif DataObject.spammy?(params, current_user)
      flash[:notice] = I18n.t(:error_violates_tos)
      self.new && return
    end
    @data_object = DataObject.create_user_text(
      params[:data_object],
      user: current_user,
      taxon_concept: @taxon_concept,
      toc_id: toc_id,
      object_created_at: Time.now,
      object_modified_at: Time.now,
      link_type_id: link_type_id,
      link_object: params[:commit_link]
    )

    if @data_object.nil? || @data_object.errors.any?
      @selected_toc_item_id = toc_id
      create_failed && return
    else
      @taxon_concept.reload # Clears caches, too!
      add_references(@data_object)
      # add this new object to the user's watch collection
      collection_item = CollectionItem.create(
        collected_item: @data_object,
        collection: current_user.watch_collection
      )
      CollectionActivityLog.create(collection: current_user.watch_collection, user_id: current_user.id,
                                   activity: Activity.collect, collection_item: collection_item)
      @data_object.log_activity_in_solr(keyword: 'create', user: current_user, taxon_concept: @taxon_concept)

      # redirect to appropriate tab/sub-tab after creating the users_data_object/link_object
      if @data_object.is_link?
        # TODO - this case definitely smells like it should be duck-typed.
        case @data_object.link_type.id
        when LinkType.blog.id
          redirect_path = news_and_event_links_taxon_resources_url(@taxon_concept, anchor: "data_object_#{@data_object.id}")
        when LinkType.news.id
          redirect_path = news_and_event_links_taxon_resources_url(@taxon_concept, anchor: "data_object_#{@data_object.id}")
        when LinkType.organization.id
          redirect_path = related_organizations_taxon_resources_url(@taxon_concept, anchor: "data_object_#{@data_object.id}")
        when LinkType.paper.id
          redirect_path = literature_links_taxon_literature_url(@taxon_concept, anchor: "data_object_#{@data_object.id}")
        when LinkType.multimedia.id
          redirect_path = multimedia_links_taxon_resources_url(@taxon_concept, anchor: "data_object_#{@data_object.id}")
        else
          redirect_path = taxon_details_path(@taxon_concept, anchor: "data_object_#{@data_object.id}")
        end
        return redirect_to redirect_path, status: :moved_permanently
      end

      # Will try to redirect to the appropriate tab/section after adding text
      subchapter = nil
      # Make sure they have the latest version of toc items:
      DataObject.with_master do
        subchapter = @data_object.toc_items.first.label.downcase
      end
      subchapter = 'literature' if subchapter == 'literature references'
      subchapter.gsub!(/ /, "_" )
      temp = ["education", "education_resources", "identification_resources", "nucleotide_sequences",
        "biomedical_terms", "citizen_science_links"] # to Resources tab
      if temp.include?(subchapter)
        return redirect_to education_taxon_resources_path(@taxon_concept,
                             anchor: "data_object_#{@data_object.id}"), status: :moved_permanently if
          ['education', 'education_resources'].include?(subchapter)
        return redirect_to identification_resources_taxon_resources_path(@taxon_concept,
                             anchor: "data_object_#{@data_object.id}"), status: :moved_permanently if
          subchapter == 'identification_resources'
        return redirect_to nucleotide_sequences_taxon_resources_path(@taxon_concept,
                             anchor: "data_object_#{@data_object.id}"), status: :moved_permanently if
          subchapter == 'nucleotide_sequences'
        return redirect_to biomedical_terms_taxon_resources_path(@taxon_concept,
                             anchor: "data_object_#{@data_object.id}"), status: :moved_permanently if
          subchapter == 'biomedical_terms'
        return redirect_to citizen_science_taxon_resources_path(@taxon_concept,
                             anchor: "data_object_#{@data_object.id}"), status: :moved_permanently if
          subchapter == 'citizen_science_links'
      elsif ["literature"].include?(subchapter)
        return redirect_to literature_taxon_literature_path(@taxon_concept,
                             anchor: "data_object_#{@data_object.id}"), status: :moved_permanently if
          subchapter == 'literature'
      end
      return redirect_to taxon_details_path(@taxon_concept, anchor: "data_object_#{@data_object.id}"), status: :moved_permanently
    end
  end

  # GET /data_objects/:id/edit
  def edit
    # @data_object is loaded in before_filter :load_data_object
    # Critical to have the latest version:
    DataObject.with_master do
      set_text_data_object_options
      @data_object.description = @data_object.description.fix_old_user_added_text_linebreaks
      @selected_toc_item_id = @data_object.toc_items.first.id rescue nil
      @selected_link_type_id = @data_object.link_type.id rescue nil
      if params[:link]
        @edit_link = true
        @page_title = I18n.t(:dato_edit_link_title)
        @page_description = I18n.t(:dato_edit_link_description)
      else
        @edit_article = true
        @page_title = I18n.t(:dato_edit_text_title)
        @page_description = I18n.t(:dato_edit_text_page_description)
        @references = @data_object.visible_references.map { |r| r.full_reference }.join("\n\n")
      end
    end
  end

  # PUT /data_objects/:id
  # NOTE we don't actually edit the data object we create a new one and unpublish the old one.
  # old @data_object is loaded in before_filter :load_data_object
  def update
    @references = params[:references]
    if DataObject.spammy?(params, current_user, refs: @references)
      update_failed(I18n.t(:error_violates_tos)) and return
    end

    # Important that you're getting the latest version:
    DataObject.with_master do
      if @data_object.users_data_object.user_id != current_user.id
        update_failed(I18n.t(:dato_update_users_text_not_owner_exception)) and return
      end
    end
    # Note: replicate doesn't actually update, it creates a new data_object
    new_data_object = @data_object.replicate(params[:data_object], user: current_user, toc_id: toc_id,
                                             link_type_id: link_type_id, link_object: params[:commit_link])
    if new_data_object.nil?
      update_failed(I18n.t(:dato_update_user_text_error)) and return
    elsif new_data_object.errors.any?
      @data_object = new_data_object # We want to show the errors...
      update_failed(I18n.t(:dato_update_user_text_error)) and return
    else
      add_references(new_data_object)
      redirect_to data_object_path(new_data_object), status: :moved_permanently
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
        render partial: 'rating', locals: { data_object: @data_object, reload_ajax_rating: true,
          minimal: params[:minimal] == 'true' ? true : false }
      end
    end

  end

  #GET /data_objects/:id/delete
  def delete
    @data_object.scrub!(current_user)
    log_action(@data_object, :delete, collect: false)
    redirect_to data_object_path(@data_object), notice: I18n.t(:data_object_deleted)
  end

  def explain
    @concepts = @data_object.associations.map(&:taxon_concept_id).
      map { |id| Concept.new(id) }
  end

  # GET /data_objects/:id
  def show
    # TODO - nononono, this isn't how DataObjectCaching is meant to be used! Call @data_object.best_title and let that class handle
    # the caching.
    @page_title = DataObjectCaching.title(@data_object, current_language)
    @slim_container = true
    DataObject.preload_associations(@data_object,
      [ { data_object_translation: { original_data_object: :language } },
        { translations: { data_object: :language } },
        { agents_data_objects: [ :agent, :agent_role ] },
        { data_objects_hierarchy_entries: { hierarchy_entry: [ :name, :taxon_concept, :vetted, :visibility ] } },
        { curated_data_objects_hierarchy_entries: { hierarchy_entry: [ :name, :taxon_concept, :vetted, :visibility ] } } ] )
    @revisions = @data_object.revisions_by_date
    @latest_published_revision = @data_object.latest_published_version_in_same_language
    @translations = @data_object.available_translations_data_objects(current_user, nil)
    @translations.delete_if{ |t| t.language.nil? } unless @translations.nil?
    @image_source = get_image_source if @data_object.is_image?
    @page = params[:page]
    @activity_log = @data_object.activity_log(ids: @revisions.collect{ |r| r.id }, page: @page || nil, user: current_user)
    set_canonical_urls(for: @data_object, paginated: @activity_log, url_method: :data_object_url)
  end

  # GET /data_objects/1/attribution
  def attribution
    render partial: 'attribution', locals: { data_object: @data_object }, layout: @layout
  end

  # GET /data_objects/1/curation
  # GET /data_objects/1/curation.js
  #
  # UI for curating a data object (ie: via the worklist)
  #
  # This is a GET, so there's no real reason to check to see whether or not the current_user can curate the object -
  # we leave that to the #curate method
  #
  def curation
  end

  def remove_association
    he = HierarchyEntry.find(params[:hierarchy_entry_id])
    cdohe = @data_object.remove_curated_association(current_user, he)
    @data_object.update_solr_index
    clear_cached_media_count_and_exemplar(he)
    log_action(cdohe, :remove_association)
    redirect_to data_object_path(@data_object), status: :moved_permanently
  end

  def save_association
    he = HierarchyEntry.find(params[:hierarchy_entry_id])
    cdohe = @data_object.add_curated_association(current_user, he)
    clear_cached_media_count_and_exemplar(he)
    @data_object.update_solr_index
    log_action(cdohe, :add_association)
    redirect_to data_object_path(@data_object), status: :moved_permanently, notice: I18n.t(:association_added_flash)
  end

  def add_association
    @querystring = params[:name]
    if @querystring.blank?
      @all_results = empty_paginated_set
    else
      search_response = EOL::Solr::SiteSearch.search_with_pagination(@querystring, params.merge({ type: ['taxon_concept'], per_page: @@results_per_page }))
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
          result_instance.entries = browsable_entries.blank? ? unbrowsable_entries : browsable_entries
        end
      end
      params.delete(:commit) unless params[:commit].blank?
      @all_results
    end
  end

  def curate_associations
    access_denied unless current_user.min_curator_level?(:full)
    store_location(params[:return_to]) # TODO - this should be generalized at the application level, it's quick, it's common.
    curations = []
    DataObject.with_master do
      @data_object.data_object_taxa.each do |association|
        curations << Curation.new(
          association: association,
          user: current_user,
          vetted: Vetted.find(params["vetted_id_#{association.id}"]),
          visibility: visibility_from_params(association),
          comment: curation_comment(params["curation_comment_#{association.id}"]), # Note, this gets saved regardless!
          untrust_reason_ids: params["untrust_reasons_#{association.id}"],
          hide_reason_ids: params["hide_reasons_#{association.id}"] )
      end
    end
    if any_errors_in_curations?(curations)
      flash[:error] = all_curation_errors_to_sentence(curations)
    else
      curations.each { |curation| curation.curate }
      DataObjectCaching.clear(@data_object)
      auto_collect(@data_object) # SPG wants all curated objects collected.
      flash[:notice] = I18n.t(:object_curated)
      @data_object.reindex
    end
    redirect_back_or_default data_object_path(@data_object.latest_published_version_in_same_language)
  end

  def ignore
    return_to = params[:return_to] unless params[:return_to].blank?
    store_location(return_to)
    if params[:undo]
      WorklistIgnoredDataObject.destroy_all("user_id = #{current_user.id} AND data_object_id = #{@data_object.id}")
    else
      @data_object.worklist_ignored_data_objects << WorklistIgnoredDataObject.create(user: current_user, data_object: @data_object)
    end
    @data_object.update_solr_index
    redirect_back_or_default
  end

  def crop
    x = params['x']
    y = params['y']
    w = params['w']
    if x && y && w && x.is_numeric? && y.is_numeric? && w.is_numeric?
      x = x.to_i
      y = y.to_i
      w = w.to_i
      # x and y can be 0
      if x >= 0 && y >= 0 && w > 0
        api_response = ContentServer.update_data_object_crop(@data_object.id, x, y, w)
        if api_response && api_response.has_key?(:response) &&
            api_response[:response].try(:is_numeric?)
          # NOTE: using update_attribute here instead of update_attribute*S* as
          # there can be harvest objects which would fail Rails validations, yet
          # we still want to update their object_cache_url
          @data_object.update_attribute('object_cache_url', api_response[:response])
          log_action(@data_object, :crop, notice: false, collect: false)
          flash[:notice] = I18n.t(:image_cropped_notice)
        else
          Rails.logger.error "Crop API failed."
          if api_response
            if api_response.has_key?(:error)
              Rails.logger.error "  API response: #{api_response[:error]}"
            else
              Rails.logger.error "  API response: #{api_response}"
            end
          else
            Rails.logger.error "  NO response"
          end
          flash[:error] = I18n.t(:image_crop_failed_error)
        end
      end
    end
    redirect_to data_object_path(@data_object)
  end

  def reindex
    @data_object.update_solr_index
    flash[:notice]= I18n.t(:this_data_object_will_be_reindexed)

    respond_to do |format|
      format.html do
        redirect_to data_object_path(@data_object)
      end
      format.js do
        convert_flash_messages_for_ajax
        render partial: 'shared/flash_messages', layout: false # JS will handle rendering these.
      end
    end
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
      dato_title: @data_object ? @data_object.best_title.presence : nil,
      dato_description: @data_object ? @data_object.description.presence : nil,
      supplier: supplier,
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
    @meta_open_graph_image_url ||= @data_object && @data_object.has_thumbnail? ?
      @data_object.thumb_or_object('260_190', specified_content_host: Rails.configuration.asset_host).presence : nil
  end

private

  def data_objects_layout
    # No layout for Ajax calls.
    return false if request.xhr?
    case action_name
    when 'edit'
      'basic'
    when 'add_association'
      'association'
    else
      'data'
    end
  end

  def curators_and_owners_only
    unless current_user.min_curator_level?(:assistant) || current_user == @data_object.user
      access_denied unless current_user.min_curator_level?(:master)
    end
  end

  def authentication_own_user_added_text_objects_only
    if !@data_object.is_text? || @data_object.users_data_object.blank? ||
       @data_object.user.id != current_user.id
      access_denied
    end
  end

  def curation_comment(comment)
    if comment.blank?
      return nil
    else
      auto_collect(@data_object) # SPG asks for all curation comments to add the item to their watchlist.
      return Comment.create(parent: @data_object, body: comment, user: current_user)
    end
  end

  def load_data_object
    with_master_if_curator do
      @data_object ||= DataObject.find(params[:id])
    end
  end

  def set_text_data_object_options
    @toc_items = TocItem.selectable_toc
    @link_types = LinkType.all
    @languages = Language.not_blank.order(:source_form)
    @licenses = License.show_to_content_partners
  end

  def create_failed
    if params[:data_object]
      flash.now[:error] = params[:commit_link] ? I18n.t(:dato_create_user_link_error) : I18n.t(:dato_create_user_text_error)
      self.new
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
      @edit_link = @data_object.is_link?
      render action: 'edit', layout: 'basic'
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

  def log_action(object, action, options={})
    CuratorActivityLog.factory(
      action: action,
      association: object,
      data_object: @data_object,
      user: current_user
    )
    unless options[:notice] === false
      flash[:notice] ||= ''
      flash[:notice]  += ' ' + I18n.t(:object_curated)
    end
    auto_collect(@data_object) unless options[:collect] === false # SPG asks for all curation to add the item to their watchlist.
  end

  def empty_paginated_set
    [].paginate(page: 1, per_page: @@results_per_page, total_entries: 0)
  end

  def clear_cached_media_count_and_exemplar(he)
    DataObjectCaching.clear(@data_object)
    he.taxon_concept.clear_for_data_object(@data_object)
  end

  def add_references(dato)
    return if params[:references].blank?
    references = params[:references].split("\n")
    unless references.blank?
      references.each do |reference|
        dato.add_ref(reference)
      end
    end
  end

  def toc_id
    id_in_params = nil
    if arr = params[:data_object].delete(:toc_items)
      id_in_params = arr[:id].to_i
    end
    @ti ||= id_in_params ? id_in_params : nil
  end

  def link_type_id
    id_in_params = nil
    if arr = params[:data_object].delete(:link_types)
      id_in_params = arr[:id].to_i
    end
    @li ||= id_in_params ? id_in_params : nil
  end

  def any_errors_in_curations?(curations)
    curations.map { |curation| curation.valid? }.include?(false)
  end

  def all_curation_errors_to_sentence(curations)
    curations.map do |curation|
      curation.errors.map { |error| I18n.t("curation_error_#{error.downcase.gsub(/\s+/, '_') }",
                                           association: curation.association.name, vetted: curation.vetted.label,
                                           visibility: curation.visibility.label ) }
    end.flatten.to_sentence
  end

  def visibility_from_params(he)
    params["visibility_id_#{he.id}"] ? Visibility.find(params["visibility_id_#{he.id}"]) : nil
  end
end
