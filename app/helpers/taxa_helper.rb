module TaxaHelper

  # These start out display:none, so we can show them only after JS behaviours have been applied.
  # which: a string to be used to create the ID of the anchor: try 'comment', 'tagging', or 'curator'.
  # where: the URL you want the anchor to reference (used by JS to create an Ajax request).
  def popup_link(which, where, options = {})
    html_options = {
      :id => "large-image-#{which}-button-popup-link", :class => 'popup-link', :style => 'display:none;'
    }.merge(options)
    link_to '<span style="display:block;width:24px;height:25px;"></span>', where, html_options
  end

  def vetted_id_class(vetted_id)
    return case vetted_id
      when Vetted.unknown.id   then 'unknown'
      when Vetted.untrusted.id then 'untrusted'
      when Vetted.trusted.id   then 'trusted'
      when Vetted.inappropriate.id   then 'inappropriate'
      else nil
    end
  end

  # entries can be an array of class types HierarchyEntry and UserDataObject and could be dirty
  # i.e. entry.vetted and entry.visibility might be overrides from e.g. DataObjectHierarchyEntry
  def collect_names_and_status(entries)
    return entries.collect do |entry|
      vetted_class = vetted_id_class(entry.vetted_id)
      vetted_label = entry.vetted == Vetted.unknown ? I18n.t(:unreviewed) : entry.vetted.label
      unless entry.class == UsersDataObject
        taxon_link = link_to entry.name.canonical, taxon_concept_path(entry.taxon_concept)
      else
        taxon_link = link_to entry.taxon_concept.canonical_form_object.string, taxon_concept_path(entry.taxon_concept)
      end
      "#{taxon_link} <span class='flag #{vetted_class}'>#{vetted_label}</span>"
    end
  end

  # used in v2 taxa details
  def category_anchor(toc_entry)
    # TODO: This probably only works if set and then used in the same page since labels on TocEntry's
    # will vary depending on language, would be better if we had machine names on TocItems instead
    toc_entry.label.gsub(/[^0-9a-z]/i, '_').strip.downcase
  end

  # used in v2 taxa overview
  def iucn_status_class(iucn_status)
    case iucn_status
    when 'Least Concern (LC)', 'Lower Risk/least concern (LR/lc)', 'Near Threatened (NT)', 'Lower Risk/near threatened (LR/nt)', 'Lower Risk/conservation dependent (LR/cd)'
      'positive'
    when 'Vulnerable (VU)', 'Endangered (EN)', 'Critically Endangered (CR)', 'Extinct in the Wild (EW)', 'Extinct (EX)'
      'negative'
    else
      # 'Data Deficient (DD)' or not evaluated
      'neutral'
    end
  end

  def citables_to_string(citables, params={})
    return '' if citables.nil? or citables.blank? or citables.class == String
    params[:linked] = true if params[:linked].nil?
    params[:only_first] ||= false
    citable_entities = citables.clone # so we can be destructive.
    citable_entities = [citable_entities] unless citable_entities.class == Array # Allows us to pass in a single agent, if needed.
    citable_entities = [citable_entities[0]] if params[:only_first]
    display_strings = citable_entities.collect do |citable|
      if citable.user
        link_to_url = user_path(citable.user)
      else
        link_to_url = params[:url] || citable.link_to_url
      end

      params[:linked] ? link_to(allow_some_html(citable.display_string), link_to_url) :
                        allow_some_html(citable.display_string)
    end
    final_string = display_strings.join(', ')
    final_string = I18n.t(:names_et_al, :names => final_string) if params[:only_first] && citables.length > 1
    return final_string
  end

  def get_hierarchy_entry_from_path
    fullpath = request.fullpath
    hierarchy_entry_id = fullpath.scan(/entries\/(.*?)\//imu)
  end

  def citables_to_icons(original_citables, params={})
    return '' if original_citables.nil? or original_citables.blank? or original_citables.class == String
    params[:linked] = true if params[:linked].nil?
    params[:show_text_if_no_icon] ||= false
    params[:only_show_col_icon] ||= false
    params[:normal_icon] ||= false
    params[:separator] ||= "&nbsp;"
    params[:last_separator] ||= params[:separator]
    params[:taxon_concept] ||= false

    is_default_col = false

    citables = original_citables.clone # so we can be destructive.
    citables = [citables] unless citables.class == Array # Allows us to pass in a single agent, if needed.

    output_html = []

    citables.each do |citable|
      url = ''
      url = citable.link_to_url.strip unless citable.link_to_url.blank?
      # if the agent is has an outlink for this taxon...
      if params[:taxon_concept]
        agent_entry = params[:taxon_concept].entry_for_agent(citable.agent_id)
        if agent_entry && outlink = agent_entry.outlink
          url = outlink[:outlink_url]
        end
      end

      logo_size = (citable.agent_id == Agent.catalogue_of_life.id ? "large" : "small") # CoL gets their logo big
      if citable.logo_cache_url.blank? && citable.logo_path.blank?
        params[:url] = url
        output_html << citables_to_string(citable) if params[:show_text_if_no_icon]
      else
        if params[:only_show_col_icon] && !is_default_col # if we are only asked to show the logo if it's COL and the current agent is *not* COL, then show text
          params[:url] = url
          output_html << citables_to_string(citable, params)
        else
          if params[:linked] and not url.blank?
            text = citable_logo(citable, logo_size, params)
            output_html << external_link_to(text, url, {:show_link_icon => false})
          else
            output_html << citable_logo(citable, logo_size, params)
          end
        end
      end
    end
    if output_html.size > 1 && params[:last_separator] != params[:separator]
      # stich the last two elements together with the "last separator" column before joining if there is more than 1 element and the last separator is different
      output_html[output_html.size-2] = output_html[output_html.size-2] + params[:last_separator] + output_html.pop
    end
    return output_html.compact.join(params[:separator])
  end

  def citable_logo(citable, size = "large", params={})
    src = nil
    if !citable.logo_cache_url.blank?
      src = Agent.logo_url_from_cache_url(citable.logo_cache_url, size)
    elsif !citable.logo_path.blank?
      src = citable.logo_path
    end
    return src if src.blank?
    project_name = hh(sanitize(citable.display_string))
    capture_haml do
      haml_tag :img, {:width => params[:width], :height => params[:height],
                      :src => src,  :border => 0, :alt => project_name,
                      :title => project_name, :class => "agent_logo"}
    end
  end

  def we_have_css_for_kingdom?(kingdom)
    return false if kingdom.nil?
    return $KINGDOM_IDs.include?(kingdom.id.to_s)
  end

  # TODO - I don't see anywhere we use this method. Would love to get rid of it, if we no longer need it :)
  # TODO - this would be useless if we put all these things into a view and show/hide the div.  Which we should:
  # def video_hash(video, taxon_concept_id='')
  #   if taxon_concept_id.blank? # grab the first taxon concept ID from the video object if we didn't just pass it in
  #     taxon_concept_ids = video.published_entries.collect{ |he| he.taxon_concept_id }
  #     taxon_concept_id = taxon_concept_ids[0] unless taxon_concept_ids.blank?
  #   end
  #   data_supplier = video.data_supplier_agent
  #   data_supplier_name = data_supplier ? data_supplier.full_name : ''
  #   data_supplier_url = data_supplier ? data_supplier.homepage : ''
  #   data_supplier_icon = data_supplier ? citables_to_icons(video.citable_data_supplier) : ''
  #
  #   trust = ''
  #   trust = 'unknown' if video.unknown?
  #   trust = 'untrusted' if video.untrusted?
  #
  #   return "{author: '"               + escape_javascript(citables_to_string(video.authors.collect{ |a| a.citable })) +
  #          "', nameString: '"         + escape_javascript(video.first_concept_name.to_s) +
  #          "', collection: '"         + escape_javascript(citables_to_string(video.sources.collect{ |a| a.citable })) +
  #          "', location: '"           + escape_javascript(video.location || '') +
  #          "', info_url: '"           + escape_javascript(video.source_url || '') +
  #          "', field_notes: '"        + escape_javascript(video.description || '') +
  #          "', license_text: '"       + escape_javascript(video.license.blank? ? '' : video.license.description || '') +
  #          "', license_logo: '"       + escape_javascript(video.license.blank? ? '' : video.license.logo_url || '') +
  #          "', license_link: '"       + escape_javascript(video.license.blank? ? '' : video.license.source_url || '') +
  #          "', title:'"               + escape_javascript(video.object_title) +
  #          "', video_type:'"          + escape_javascript(video.data_type.label) +
  #          "', video_trusted:'"       + escape_javascript(video.vetted_id.to_s) +
  #          "', trust:'"               + escape_javascript(trust) +
  #          "', video_data_supplier:'" + escape_javascript(data_supplier.to_s) +
  #          "', video_supplier_name:'" + escape_javascript(data_supplier_name.to_s) +
  #          "', video_supplier_url:'"  + escape_javascript(data_supplier_url.to_s) +
  #          "', video_supplier_icon:'" + escape_javascript(data_supplier_icon.to_s) +
  #          "', video_url:'"           + escape_javascript(video.video_url.to_s || video.object_url || '') +
  #          "', data_object_id:'"      + escape_javascript(video.id.to_s) +
  #          "', mime_type_id:'"        + escape_javascript(video.mime_type_id.to_s) +
  #          "', object_cache_url:'"    + escape_javascript(video.object_cache_url.to_s) +
  #          "', taxon_concept_id:'#{taxon_concept_id}'}"
  #
  # end

  def reformat_specialist_projects(projects)
    max_columns = 2
    num_mappings = projects.size
    num_columns = num_mappings < max_columns ? num_mappings : max_columns
    res = []
    until projects.blank? do
      res << projects.shift(num_columns)
    end
    (num_columns - res[-1].size).times do
      res[-1] << nil
    end
    [res, num_columns]
  end

  def hierarchy_outlink_collection_types(hierarchy)
    links = []
    hierarchy.collection_types.uniq.each do |collection_type|
      links << collection_type.materialized_path_labels
    end
    partner_label = hierarchy_or_resource_name(hierarchy)
    links.empty? ? partner_label : links.join(', ')
  end

  def hierarchy_or_resource_name(hierarchy)
    if(hierarchy.resource)
      partner_label = hierarchy.resource.title
    else
      partner_label = hierarchy.label
    end
  end

  # TODO - move this to CommonNameDisplay
  def common_names_by_language(names, preferred_language_id)
    names_by_language = {}
    # Get some languages we'll need
    eng     = Language.english
    pref    = Language.find(preferred_language_id)
    unknown = Language.unknown
    # Build a hash with language label as key and an array of CommonNameDisplay objects as values
    names.each do |name|
      k = name.language_label.dup
      k = unknown.label if k.blank?
      names_by_language.key?(k) ? names_by_language[k] << name : names_by_language[k] = [name]
    end
    results = []
    # Put preferred first
    results << [pref.label, names_by_language.delete(pref.label)] if names_by_language.key?(pref.label)
    # Sort the rest by language label
    names_by_language.to_a.sort_by {|a| a[0].to_s.downcase }.each {|a| results << a}
    results
  end

# A *little* weird to have private methods in the helper, but these really help clean up the code for the methods
# that are public, and, indeed, should never be called outside of this class.
private

  def search_by_page_href(link_page)
    lparams = params.clone
    lparams["page"] = link_page
    lparams.delete("action")
    "/search/?#{lparams.to_query}"
  end

  # TODO - move this to CommonNameDisplay
  def remove_duplicate_names(names)
    names.each do |lang, names_in_language|
      names_in_language.each_with_index do |name_a, index_a|
        names_in_language.each_with_index do |name_b, index_b|
          next if index_a == index_b
          if name_a.name.id == name_b.name.id
            name_a.duplicate = true
            name_b.duplicate = true
            # name_a.duplicate_with_curator = true if name_b.trusted_by_agent?
            # name_b.duplicate_with_curator = true if name_a.trusted_by_agent?
          end
        end
      end
      # Remove entries that are duplicates in the curator hierarchy
      names_in_language.delete_if {|name| name.duplicate_with_curator }
    end
  end

end
