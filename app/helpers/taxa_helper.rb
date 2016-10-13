module TaxaHelper

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
      unless entry.class == UsersDataObject
        taxon_link = link_to raw(entry.title_canonical_italicized), taxon_overview_path(entry.taxon_concept)
      else
        taxon_link = link_to raw(entry.taxon_concept.entry.title_canonical_italicized), taxon_overview_path(entry.taxon_concept)
      end
      "#{taxon_link} <span class='flag #{vetted_id_class(entry.vetted_id)}'>#{entry.vetted.curation_label}</span>"
    end
  end

  # used in v2 taxa details
  def category_anchor(toc_entry)
    # TODO: This probably only works if set and then used in the same page since labels on TocEntry's
    # will vary depending on language, would be better if we had machine names on TocItems instead
    toc_entry.label.gsub(/[^0-9a-z]/i, '_').strip.downcase if toc_entry.label
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
    partner_label = hierarchy.display_title
    links.empty? ? partner_label : links.join(', ')
  end

  def hierarchy_entry_display_attribution(hierarchy_entry, options={})
    # on the overview page we show he rank first (Species recognized by ...)
    # otherwise we show the rank last (... as a Species)
    options[:show_rank_first] ||= false
    hierarchy_title = hierarchy_display_title(hierarchy_entry.hierarchy, options)
    if hierarchy_entry.has_source_database?
      recognized_by = hierarchy_entry.recognized_by_agents.map(&:full_name).to_sentence
      if options[:show_rank_first]
        return I18n.t(:rank_recognized_by_from_source, agent: recognized_by, source: hierarchy_title,
                      rank: hierarchy_entry.rank_label)
      elsif options[:show_rank] == false
        return I18n.t(:recognized_by_from_source, recognized_by: recognized_by, source: hierarchy_title)
      else
        return I18n.t(:recognized_by_from_source_as_a_rank, recognized_by: recognized_by,
                      source: hierarchy_title, taxon_rank: hierarchy_entry.rank_label)
      end
    else
      if options[:show_rank_first]
        return I18n.t(:rank_recognized_by_agent, agent: hierarchy_title, rank: hierarchy_entry.rank_label)
      elsif options[:show_rank] == false
        return hierarchy_title
      else
        return I18n.t(:recognized_by_as_a_rank, recognized_by: hierarchy_title,
                      taxon_rank: hierarchy_entry.rank_label)
      end
    end
  end

  def hierarchy_display_title(hierarchy, options={})
    options[:show_link] = true if !options.has_key?(:show_link)
    hierarchy_label = hierarchy.display_title
    if options[:show_link] && cp = hierarchy.content_partner
      hierarchy_label = link_to(hierarchy_label, cp)
    end
    return hierarchy_label
  end

  def common_name_display_attribution(common_name_display)
    agent_names = common_name_display.agents.map do |a|
      if a.user
        link_to a.user.full_name(ignore_empty_family_name: true), a.user
      else
        a.full_name
      end
    end
    hierarchy_labels = common_name_display.hierarchies.map { |h| hierarchy_display_title(h, show_link: false) }

    all_attribution = (agent_names + hierarchy_labels).compact.uniq.sort.join(', ')
    # This is *kind of* a hack.  Long, long ago, we kinda mangled our data by not having synonym IDs
    # for uBio names, so uBio became the 'default' common name provider
    all_attribution = "uBio" if all_attribution.blank?
    all_attribution
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
      k = name.language_label ? name.language_label.dup : nil
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

  def association_belongs_to_taxon_concept?(association, taxon_concept)
    taxon_concept_ancestors_for_association = association.taxon_concept.flattened_ancestors.map(&:ancestor_id).sort.uniq
    taxon_concept_ancestors_for_association << association.taxon_concept.id if association.taxon_concept
    !taxon_concept_ancestors_for_association.blank? && taxon_concept_ancestors_for_association.include?(taxon_concept.id)
  end

  # TODO - this has gotten sloppy.  Refactor.
  def display_uri(uri, options = {})
    options[:succeed] ||= ''
    options[:without_label] ||= false
    options[:search_link] = true unless options.has_key?(:search_link)
    # display_label = uri
    display_label = DataValue.new(uri, value_for_known_uri: options[:value_for_known_uri]).label
    tag_type = (options[:define] && ! options[:val] || options[:ranges]) ? 'div' : 'span'
    tag_type << ".#{options[:class]}" if options[:class]
    capture_haml do
      info_icon if options[:define] && ! options[:val]
      if options[:define] && options[:define] != :after && uri.is_a?(KnownUri)
        define(tag_type, uri, options[:search_link])
      end
      haml_tag("#{tag_type}.term", 'data-term' => uri.is_a?(KnownUri) ? uri.anchor : nil) do
        haml_concat add_exemplar_or_excluded_icon(options)
        haml_concat raw(format_data_value(display_label, options)) + options[:succeed] unless
          options[:without_label]
        haml_concat display_text_for_modifiers(options[:modifiers])
        if ( options[:define] &&
          options[:define] == :after ||
          options[:ranges] ) &&
          uri.is_a?(KnownUri)
          define(tag_type, uri, options[:search_link])
          info_icon if options[:val]
        end
      end
    end
  end

  def add_exemplar_or_excluded_icon(options)
    if current_user.min_curator_level?(:full)
      if options[:exemplar]
        image_tag('v2/icon_required.png', title: I18n.t(:data_tab_curator_exemplar), alt: I18n.t(:data_tab_curator_exemplar))
      elsif options[:excluded]
        image_tag('v2/icon_excluded.png', title: I18n.t(:data_tab_curator_excluded), alt: I18n.t(:data_tab_curator_excluded))
      end
    end
  end

  def display_association(data_point_uri, options = {})
    taxon_link = options[:link_to_overview] ?
      taxon_overview_path(data_point_uri.target_taxon_concept) :
      taxon_data_path(data_point_uri.target_taxon_concept)
    if c = data_point_uri.target_taxon_concept.preferred_common_name_in_language(current_language)
      link_to c, taxon_link
    else
      link_to raw(data_point_uri.target_taxon_concept.title_canonical), taxon_link
    end
  end

  def format_data_value(value, options={})
    value = value.is_a?(DataValue) ? value.label.to_s : value.to_s
    if convert_numbers?(value, options)
      if value.is_float?
        if value.to_f < 0.1
          # floats like 0.01234 need to round off to at least 2 significant digits
          # getting 3 here allows for values like 1.23e-10
          value = value.to_f.sigfig_to_s(3)
        else
          # float values can be rounded off to 2 decimal places
          value = value.to_f.round(2)
        end
      end
      value = number_with_delimiter(value, delimiter: ',')
    else
      # other values may have links embedded in them (references, citations, etc.)
      value = value.add_missing_hyperlinks
      value = value.firstcap if options[:capitalize]
    end
    value
  end

  def convert_numbers?(value, options = {})
    value.is_numeric? &&
      !(options[:value_for_known_uri] &&
        options[:value_for_known_uri].respond_to?(:treat_as_string?) &&
        options[:value_for_known_uri].treat_as_string?)
  end

  # TODO - this has too much business logic; extract
  def display_text_for_data_point_uri(data_point_uri, options = {})
    # Metadata rows do not have DataPointUris that are saved in the DB - they are new records.
    # Otherwise generate an ID or use the given one (measurements can be shown multiple times on a page
    # and each one needs a different ID if we want them all to have tooltips)
    text_for_row_value = data_point_uri.new_record? ? "" : "<span id='#{options[:id] || data_point_uri.anchor}'>"
    if data_point_uri.association?
      text_for_row_value += display_association(data_point_uri, options)
    else
      text_for_row_value += display_uri(data_point_uri.object_uri, options.merge(val: true)).to_s
    end
    # displaying unit of measure
    if data_point_uri.unit_of_measure_uri && uri_components = EOL::Sparql.explicit_measurement_uri_components(data_point_uri.unit_of_measure_uri)
      text_for_row_value += " " + display_uri(uri_components, val: true)
    elsif uri_components = EOL::Sparql.implicit_measurement_uri_components(data_point_uri.predicate_uri)
      text_for_row_value += " " + display_uri(uri_components, val: true)
    end
    adjust_exponent(text_for_row_value)
    text_for_row_value.gsub(/\n/, '')
    text_for_row_value += "</span>" unless data_point_uri.new_record?
    # displaying context such as life stage, sex.... The overview tab will include the statistical modifier
    modifiers = data_point_uri.context_labels
    if options[:include_statistical_method] && data_point_uri.statistical_method_label
      modifiers.unshift(data_point_uri.statistical_method_label)
    end
    text_for_row_value += display_text_for_modifiers(modifiers)
    text_for_row_value
  end

  def adjust_exponent(text_for_row_value)
    text_for_row_value.gsub!(/\^(\S)/, "<sup style='vertical-align: baseline;position: relative;top: -0.4em;'>\\1</sup>")
  end

  # This actually gets REVMOVED by JS (and replaced with the definition), which
  # seems a little odd, but I believe it's meant to support non-JS users.
  def info_icon
    haml_tag "a.info_icon" do
      haml_concat "&emsp;" # Width doesn't seem to work.  :|
    end
  end

  def display_text_for_modifiers(modifiers)
    if modifiers && ! modifiers.empty?
      modifiers = modifiers.compact.uniq
      unless modifiers.empty?
        return "<span class='stat'>#{modifiers.join(', ')}</span>"
      end
    end
    ''
  end

  def define(tag_type, uri, search_link)
    haml_tag "span.info" do
      haml_tag "ul.glossary" do
        haml_concat render(partial: 'known_uris/definition', locals: { known_uri: uri, search_link: search_link, glossary_link: true })
      end
    end
  end

  def glossary_define(known_uri, options = {})
    return if known_uri.nil?
    return unless known_uri.is_a?(KnownUri)
    options.reverse_merge!(
      search_link: false,
      top_link: false,
      glossary_link: false,
      attribution: false,
      glossary_permalink: false
    )

    haml_tag "ul.glossary" do
      haml_tag(:li, id: known_uri.anchor, data: { toc_id: known_uri.toc_items.collect(&:id).join(' ') }) do
        haml_tag(:dt, known_uri.name)
        unless known_uri.definition.blank?
          haml_tag(:dd, known_uri.definition.add_missing_hyperlinks.html_safe)
        end
        if options[:attribution] && ! known_uri.attribution.blank?
          haml_tag("dd.attribution", known_uri.attribution.add_missing_hyperlinks.html_safe)
        end
        haml_tag("dd.uri", known_uri.uri)
        haml_tag "ul.helpers" do
          if options[:top_link]
            haml_tag(:li, link_to(I18n.t(:link_to_top_of_page), '#'))
          end
          if options[:glossary_link]
            haml_tag(:li, link_to(I18n.t(:see_in_data_glossary),
              data_glossary_url(anchor: known_uri.anchor), class: :glossary,
              data: { anchor: known_uri.anchor, tab_link_message: I18n.t(:see_in_glossary_tab) }))
          elsif options[:glossary_permalink]
            haml_tag(:li, link_to(I18n.t(:link_to_this_term),
              data_glossary_url(anchor: known_uri.anchor), class: :glossary,
              data: { anchor: known_uri.anchor }))
          end
          if options[:search_link] && known_uri.measurement?
            haml_tag(:li, link_to(I18n.t(:more_taxa_with_attribute),
              data_search_path(attribute: known_uri.uri, sort: 'desc')))
          end
          if current_user.is_admin?
            haml_tag("li.hover", link_to(I18n.t(:edit),
              edit_known_uri_path(known_uri)))
          end
        end
      end
    end
  end

  def defn(known_uri, options = {})
    haml_tag "span.info" do
      glossary_define(known_uri, options = {})
    end
  end
end
