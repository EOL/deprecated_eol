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
        taxon_link = link_to entry.name.canonical, taxon_overview_path(entry.taxon_concept)
      else
        taxon_link = link_to entry.taxon_concept.canonical_form_object.string, taxon_overview_path(entry.taxon_concept)
      end
      "#{taxon_link} <span class='flag #{vetted_id_class(entry.vetted_id)}'>#{entry.vetted.curation_label}</span>"
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
  
  def hierarchy_display_title(hierarchy, options={})
    options[:show_link] = true if !options.has_key?(:show_link)
    hierarchy_label = hierarchy.display_title
    if options[:show_link] && cp = hierarchy.content_partner
      hierarchy_label = link_to(hierarchy_label, cp)
    end
    return hierarchy_label
  end
  
  def hierarchy_entry_display_attribution(hierarchy_entry, options={})
    # on the overview page we show he rank first (Species recognized by ...)
    # otherwise we show the rank last (... as a Species)
    options[:show_rank_first] ||= false
    hierarchy_title = hierarchy_display_title(hierarchy_entry.hierarchy, options)
    
    if hierarchy_entry.has_source_database?
      recognized_by = hierarchy_entry.recognized_by_agents.map(&:full_name).to_sentence
      # recognized_by = hierarchy_entry.recognized_by_agents.map {|a| (a.respond_to?(:user) && a.user && a.user.respond_to?(:content_partners) && !a.user.content_partners.blank?) ? link_to(a.full_name, content_partner_path(a.user.content_partners.first)) : a.full_name }.to_sentence
      if options[:show_rank_first]
        return I18n.t(:rank_recognized_by_from_source, :agent => recognized_by, :source => hierarchy_title, :rank => hierarchy_entry.rank_label)
      elsif options[:show_rank] == false
        return I18n.t(:recognized_by_from_source, :recognized_by => recognized_by, :source => hierarchy_title)
      else
        return I18n.t(:recognized_by_from_source_as_a_rank, :recognized_by => recognized_by, :source => hierarchy_title, :taxon_rank => hierarchy_entry.rank_label)
      end
    else
      if options[:show_rank_first]
        return I18n.t(:rank_recognized_by_agent, :agent => hierarchy_title, :rank => hierarchy_entry.rank_label)
      elsif options[:show_rank] == false
        return hierarchy_title
      else
        return I18n.t(:recognized_by_as_a_rank, :recognized_by => hierarchy_title, :taxon_rank => hierarchy_entry.rank_label)
      end
    end
  end
  
  def common_name_display_attribution(common_name_display)
    agent_names = common_name_display.agents.map do |a|
      if a.user
        link_to a.user.full_name(:ignore_empty_family_name => true), a.user
      else
        a.full_name
      end
    end
    hierarchy_labels = common_name_display.hierarchies.map { |h| hierarchy_display_title(h, :show_link => false) }
    
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

end
