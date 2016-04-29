class TaxaController < ApplicationController

  layout 'taxa'

  # If we happen to be on an SSL page, go back to http:
  prepend_before_filter :redirect_back_to_http if $USE_SSL_FOR_LOGIN
  before_filter :redirect_if_superceded

  def show
    if this_request_is_really_a_search
      do_the_search
      return
    end
    return redirect_to taxon_overview_path(params[:id]), status: :moved_permanently
  end

  ################
  # AJAX CALLS
  ################

  def publish_wikipedia_article
    tc = TaxonConcept.find(params[:taxon_concept_id].to_i)
    data_object = DataObject.find(params[:data_object_id].to_i)
    data_object.publish_wikipedia_article(tc)

    category_id = params[:category_id].to_i
    redirect_url = "/pages/#{tc.id}"
    redirect_url += "?category_id=#{category_id}" unless category_id.blank? || category_id == 0
    redirect_to redirect_url
  end

  def lookup_reference
    ref = Ref.find(params[:ref_id].to_i)
    callback = params[:callback]

    if defined? $REFERENCE_PARSING_ENABLED
      raise 'Reference parsing disabled' if !$REFERENCE_PARSING_ENABLED
    else
      parameter = EolConfig.reference_parsing_enabled
      raise 'Reference parsing disabled' unless parameter && parameter.value == 'true'
    end

    if defined? $REFERENCE_PARSER_ENDPOINT
      endpoint = $REFERENCE_PARSER_ENDPOINT
    else
      endpoint_param = EolConfig.reference_parser_endpoint
      endpoint = endpoint_param.value
    end

    if defined? $REFERENCE_PARSER_PID
      pid = $REFERENCE_PARSER_PID
    else
      pid_param = EolConfig.reference_parser_pid
      pid = pid_param.value
    end

    raise 'Invalid configuration' unless pid && endpoint

    url = endpoint + "?pid=#{pid}&output=json&q=#{URI.escape(ref.full_reference)}&callback=#{callback}"
    render text: Net::HTTP.get(URI.parse(url))
  end

protected

  # Defines the scope of the controller and action method (i.e. view path) for using in i18n calls
  # Used by meta tag helper methods (also see ApplicationController for #super)
  def controller_action_scope
    @controller_action_scope ||= @selected_hierarchy_entry ? super << :hierarchy_entry : super
  end

  # Defines base variables for use in scoped i18n calls, used by meta tag helper methods (also see
  # ApplicationController for #super)
  def scoped_variables_for_translations
    @scoped_variables_for_translations ||= super.dup.merge({
      preferred_common_name: @preferred_common_name.presence,
      scientific_name: @scientific_name.presence,
      hierarchy_provider: @taxon_page.hierarchy_provider,
    }).freeze
  end

  def meta_title
    return @meta_title if defined?(@meta_title)
    translation_vars = scoped_variables_for_translations.dup
    translation_vars[:default] = [translation_vars[:preferred_common_name],
                                  translation_vars[:scientific_name],
                                  translation_vars[:hierarchy_provider],
                                  @assistive_section_header].compact.join(" - ")
    @meta_title = t(".meta_title#{translation_vars[:preferred_common_name] ? '_with_common_name' : ''}", translation_vars)
  end

  def meta_description
    @meta_description ||= t(".meta_description#{scoped_variables_for_translations[:preferred_common_name] ? '_with_common_name' : ''}",
                            scoped_variables_for_translations.dup)
  end

  def meta_keywords
    return @meta_keywords if defined?(@meta_keywords)
    translation_vars = scoped_variables_for_translations.dup
    keywords = [ translation_vars[:preferred_common_name],
      translation_vars[:scientific_name],
      translation_vars[:preferred_common_name] && @assistive_section_header ? "#{translation_vars[:preferred_common_name]} #{@assistive_section_header}" : nil,
      translation_vars[:scientific_name] && @assistive_section_header ? "#{translation_vars[:scientific_name]} #{@assistive_section_header}" : nil,
      translation_vars[:hierarchy_provider]
    ].uniq.compact.join(", ")
    additional_keywords = t(".meta_keywords#{translation_vars[:preferred_common_name] ? '_with_common_name' : ''}",
                            translation_vars)
    @meta_keywords = [keywords, additional_keywords.presence].compact.join(', ')
  end

  def meta_open_graph_image_url
    @meta_open_graph_image_url ||= (@taxon_concept && dato = @taxon_concept.exemplar_or_best_image_from_solr) ?
       dato.thumb_or_object('260_190', specified_content_host: Rails.configuration.asset_host).presence : nil
  end

private

  def instantiate_taxon_page
    tc_id = params[:taxon_concept_id] || params[:taxon_id] || params[:id]
    # we had cases of app servers not properly getting the page ID from
    # parameters and throwing 404 errors instead of 500. This may cause site
    # crawlers to think pages don't exist. So throw errors instead
    raise if tc_id.blank? || tc_id == 0
    with_master_if_curator do
      # Doing a "dance" here to get the superceded id, then load it with
      # associations:
      super_id = TaxonConcept.find(tc_id).id
      @taxon_concept = TaxonConcept.with_titles.find(super_id)
      @superceded = super_id.to_s != tc_id.to_s
    end
    unless @taxon_concept.published?
      if logged_in?
        unless @taxon_concept.can_be_previewed_by?(current_user)
          raise EOL::Exceptions::SecurityViolation.
            new("User with ID=#{current_user.id} does not have access to "\
              "TaxonConcept with id=#{@taxon_concept.id}",
            :can_not_access_unpublished_taxon)
        end
        flash[:notice] = I18n.t(:previewing_unpublished_page)
      else
        raise EOL::Exceptions::MustBeLoggedIn, "Non-authenticated user does "\
          "not have access to TaxonConcept with ID=#{@taxon_concept.id}"
      end
    end

    @selected_hierarchy_entry_id = params[:hierarchy_entry_id] || params[:entry_id]
    if @selected_hierarchy_entry_id.nil? && entry_id_is_in_param_id?
      @selected_hierarchy_entry_id = params[:id]
    end
    unless @selected_hierarchy_entry_id.blank?
      @selected_hierarchy_entry =
        HierarchyEntry.find(@selected_hierarchy_entry_id) rescue nil
      @selected_hierarchy_entry = nil unless @selected_hierarchy_entry &&
        @selected_hierarchy_entry.hierarchy.browsable?
    end
    @taxon_page = TaxonPage.new(@taxon_concept, current_user,
      @selected_hierarchy_entry)
  end

  def instantiate_preferred_names
    @preferred_common_name = @taxon_concept.
      preferred_common_name_in_language(current_language)
    @scientific_name = @taxon_page.scientific_name
  end

  def redirect_if_superceded
    if @taxon_concept && @superceded
      redirect_to url_for(controller: params[:controller],
        action: params[:action], taxon_id: @taxon_concept.id),
        status: :moved_permanently
      return false
    end
  end

  def get_new_text_tocitem_id(category_id)
    if category_id && toc = TocItem.find_by_id(category_id)
      return category_id if toc.allow_user_text?
    end
    return 'none'
  end

  def this_request_is_really_a_search
    tc_id = params[:id].to_i
    tc_id = params[:taxon_id].to_i if tc_id == 0
    tc_id == 0
  end

  def do_the_search
    redirect_to search_path(q: params[:id])
  end

  def is_common_names?(category_id)
    TocItem.common_names.id == category_id
  end

  def build_language_list
    current_user_copy = current_user.dup || nil
    @languages = Language.with_iso_639_1.map do |lang|
      { label: lang.label,
        id: lang.id,
        selected: lang.id == (current_user_copy && current_user_copy.language.id) ? "selected" : nil
      }
    end
  end

  def log_action(tc, target, method)
    auto_collect(tc) # SPG asks for all curation (including names) to add the item to their watchlist.
    # NOTE - Don't pass :data_object into this; it will overwrite the value of :target_id.
    CuratorActivityLog.create(
      user_id: current_user.id,
      changeable_object_type: ChangeableObjectType.send(target.class.name.underscore.to_sym),
      target_id: target.id,
      activity: Activity.send(method),
      taxon_concept_id: tc.id
    )
  end

  def entry_id_is_in_param_id?
    params[:taxon_id] && params[:id] && request.env['PATH_INFO'] =~ /^\/pages\/[0-9]+\/hierarchy_entries\/[0-9]+\//
  end

end
