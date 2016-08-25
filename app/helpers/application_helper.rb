module ApplicationHelper

  # Used in V2 to allow block elements in forms
  # adds error class and title attributes to form elements
  # adds error messages after label
  class EolFormBuilder < ActionView::Helpers::FormBuilder

    def text_area(method, options = {})
      (options['class'] = "#{options['class'].to_s} errors").strip! if errors_on?(method)
      super(method, options)
    end

    def text_field(method, options = {})
      (options['class'] = "#{options['class'].to_s} errors").strip! if errors_on?(method)
      super(method, options)
    end

    def password_field(method, options = {})
      (options['class'] = "#{options['class'].to_s} errors").strip! if errors_on?(method)
      super(method, options)
    end

    # TODO: If there is a block can we have a flag or something to automatically prepend or append the
    # translated label without having to explicitly call I18n method?
    def label(method, content_or_options_with_block = nil, options = {}, &block)
      options = content_or_options_with_block if content_or_options_with_block.is_a?(Hash)
      options.symbolize_keys!
      if errors_on?(method) && !options[:hide_errors]
        (options[:class] = "#{options[:class].to_s} errors").strip!
        (options[:title] = "#{options[:title].to_s} #{I18n.t(:form_validation_errors_for_attribute_assistive)}").strip!
        errors = errors_for_method(@object, method)
      end

      if block_given?
        @template.content_tag(:label, "#{@template.capture(&block)} #{errors.to_s}".html_safe, options)
      else
        super(method, content_or_options_with_block, options) + (errors ? @template.content_tag(:span, errors.to_s) : nil)
      end
    end

    # tags can include :all, :minimal (default) or a comma separated string of tags
    def allowed_html_help_tip(tags = :minimal)
      return nil
      # tags = "p, em, strong, a, ul, ol, li" if tags.to_sym == :minimal
      # tags = "p, em, strong, a, ul, ol, li, table, tr, td" if tags.to_sym == :all
      # return I18n.t(:allowed_html_tags, comma_separated_tags: tags)
    end

  private

    def errors_on?(method)
      @object.respond_to?(:errors) && @object.errors.respond_to?(:messages) && ! @object.errors.messages[method.to_sym].blank?
    end

    def errors_for_method(object, method)
      return unless errors_on?(method)
      errors = object.errors.messages[method.to_sym]
      if errors.any?
        errors = [errors] if errors.is_a? String
        @template.content_tag(:span, { class: 'errors' }){ " " + errors.join(", ") }
      end
    end
  end
  # Used in V2, removes div#fieldWithErrors errors identified by class on form element instead see EolFormBuilder
  ActionView::Base.field_error_proc = Proc.new do |html_tag, instance_tag|
    html_tag
  end
  # Used in V2 to render all validation errors for a form
  # form.error_messages and form.error_messages_for are deprecated in Rails 3
  def validation_errors_for(resource, message = nil)
    if resource.errors.any?
      message ||= I18n.t('activerecord.errors.template.header', count: resource.errors.size, model: '')
      capture_haml do
        haml_tag 'fieldset#errors' do
          haml_tag :legend, message
          haml_tag :ul do
            resource.errors.full_messages.each do |error|
              haml_tag :li, raw(error)
            end
          end
        end
      end
    end
  end

  # Used in V2 to return class for active navigation tabs.
  def resource_is_active(action)
    return "active" if
        action == "#{controller.controller_name}/#{controller.action_name}" ||
        action == controller.controller_name ||
        action == controller.action_name ||
        action.downcase == controller.class.to_s.downcase
    return nil
  end

  # Recommended by https://github.com/rails/jquery-ujs
  def csrf_meta_tag
    if protect_against_forgery?
      out = %(<meta name="csrf-param" content="%s"/>\n)
      out << %(<meta name="csrf-token" content="%s"/>)
      out % [ Rack::Utils.escape_html(request_forgery_protection_token),
              Rack::Utils.escape_html(form_authenticity_token) ]
    end
  end

  # Used to provide a stable English type label for CSS and I18n keys
  def self.en_type(object)
    if object.class == CollectionItem
      en_type(object.collected_item)
    elsif object.class == DataObject
      return 'image_map' if object.is_image_map? # NOTE: this must appear before is_image? here
      return 'map' if object.is_map?
      return 'image' if object.is_image?
      return 'video' if object.is_video?
      return 'sound' if object.is_sound?
      return 'link' if object.is_link?
      return 'article' if object.is_text?
    elsif object.class == Community
      'community'
    elsif object.class == Collection
      'collection'
    elsif object.class == TaxonConcept
      'taxon'
    elsif object.class == User
      'person'
    elsif object.class == ContentPage
      'cms_page'
    end
  end
  def en_type(object)
    return ApplicationHelper.en_type(object)
  end

  # Used in V2 to provide semi-useful alternative text for data object image representations
  # TODO: These alt/title attributes are fairly useless in terms of accessibility.
  # We used to show part of the description, but that caused us to use Sanitize, sometimes
  # multiple times which was horrendous for performance. We used to use the I18n key
  # "#{en_type}_alt_text". We should think about what the best alt text would be and
  # figure out how to get that as fast as possible (alternative to Sanitize? No sanitizing at all?)
  def alternative_text(data_object, en_type, taxon_concept = nil)
    if taxon_concept && taxon_concept.class == TaxonConcept && title = taxon_concept.title_canonical
      I18n.t("#{en_type}_of_taxon", taxon_name: title)
    else
      I18n.t("item_type_#{en_type}_assistive", taxon_name: title)
    end
  end

  # A little onclick magic to make Ajaxy-links work before the page is fully loaded.  JS in the application.js file will
  # handle all the rest after the page is fully loaded (because of the class added to the link).
  # Use it like this:
  #   link_to( I18n.t(:text) , "#", class: 'ajax_delay_click', onclick: ajax_delay_click)
  def ajax_delay_click
    %Q{javascript:$(this).addClass('delayed_click');$('#ajax-indicator').fadeIn();return false;}
  end

  def ajax_spinner
    image_tag("indicator_arrows_black.gif", alt:  I18n.t(:please_wait) , class: 'hidden spinner')
  end

  def license_title_or_empty(license)
    license.blank? ? I18n.t(:value_empty) : I18n.t("license_#{license.title.gsub(/[- .]/, '_').strip}")
  end

  def format_date_time(inTime,params={})
    return '[blank]' if inTime.blank?
    if inTime.is_a? String
      inTime = Time.parse(inTime)
    end
    inTime.to_s(params[:format] || :long).to_sym
  end

  # Return a formatted date
  # Default format: %m/%d/%Y
  def format_date(date, format = "%m/%d/%Y")
    date.respond_to?(:strftime) ? date.strftime(format) : date.to_s
  end

  # similar to h, but does not escape html code which is helpful for showing italisized names
  # TODO - stop using this.  Trust, instead, the built-in method (in views) called #sanitize
  def hh(input)
    return nil if input.nil?
    result = input.dup.strip

    result.gsub!(/["]|&(?![\w]+;)/) do | match |
      case match
        when '&' then '&amp;'
        when '"' then '&quot;'
        else          ''
      end
    end
    result
  end

  def external_link_icon
    image_tag('external_link.png',{ alt: I18n.t(:external_link_icon_alt_text) })
  end

  def taxon_concept_comments_path(taxon_concept)
    return "/taxon_concepts/#{taxon_concept.id}/comments/"
  end

  def contact_us_requests_path
    return "/contact_us_request_path/create"
  end

  # format numbers with commas for digit separators
  def format_number_with_commas(st)
    st.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  end

  # Link to a single stylesheet asset (which may be comprised of several individual files).
  # NOTE - Styles will only be cached for English. Sorry; impractical to maintain copies of all cached files for
  # every language.
  def stylesheet_include_i18n_merged(stylesheet, options = {})
    code = ''
    # get the replacements
    language_css_path = Rails.root.join("app", "assets", "stylesheets", "languages", I18n.locale.to_s, "#{stylesheet}.css")
    language_sass_path = Rails.root.join("app", "assets", "stylesheets", "languages", I18n.locale.to_s, "#{stylesheet}.sass")
    if File.exists?(language_css_path) || File.exists?(language_sass_path)
      code += stylesheet_link_tag("languages/#{I18n.locale}/#{stylesheet}", options)
    else
      code += stylesheet_link_tag(stylesheet, options)
    end

    # get the additions
    language_css_path = Rails.root.join("app", "assets", "stylesheets", "languages", I18n.locale.to_s, "#{stylesheet}_include.css")
    language_sass_path = Rails.root.join("app", "assets", "stylesheets", "languages", I18n.locale.to_s, "#{stylesheet}_include.sass")
    if File.exists?(language_css_path) || File.exists?(language_sass_path)
      code += stylesheet_link_tag("languages/#{I18n.locale}/#{stylesheet}_include", options)
    end
    return raw(code)
  end

  # Version of error_messages_for that displays translated error messages
  # View the <custom></custom> section to see the relevant pieces changed from original
  # TODO: Move to a plugin?
  def eol_lang_error_messages_for(*params)
    options = params.extract_options!.symbolize_keys
    object = options.delete(:object)
    objects = object ? [object].flatten : params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
    count = objects.inject(0) {|sum, obj| sum + obj.errors.count }
    unless count.zero?
      html = {}
      [:id, :class].each do |key|
        if options.include?(key)
          value = options[key]
          html[key] = value unless value.blank?
        else
          html[key] = 'errorExplanation'
        end
      end
      options[:header_message] = I18n.t(:validation_error)  unless options.include?(:header_message)
      options[:message] ||=  I18n.t(:validation_following_fields)  unless options.include?(:message)

      # Translate error messages
      error_messages = objects.map do |obj|
        obj.errors.map do |field, error|
          # Try translating the field name
          field = ActiveRecord::Base.human_attribute_name(field)

          # Make two versions of the error message:
          #   Example: is too short (minimum 3 characters)
          #   1) is too short (minimum %d characters)
          #   Use this to map with default_error_messages_inverted
          #   2) is too short (minimum {n} characters)
          #   Use this for Gibberish to translate with variables
          error_attributes = error.scan(/\d+/)
          error_default = error.gsub(/\d+/,"%d")
          error_translate = error.gsub(/\d+/,"{n}") #

          if error =~ /^\^/
            error_display = error[1..-1]
          else
            error_display =  "#{field == 'Base' ? '' : field} #{error}"
          end
          content_tag(:li, error_display)
        end
      end

      contents = ''
      contents << content_tag(options[:header_tag] || :h2, options[:header_message]) unless options[:header_message].blank?
      contents << content_tag(:p, options[:message]) unless options[:message].blank?
      contents << content_tag(:ul, raw(error_messages.flatten.join))
      content_tag(:div, raw(contents), html)
    else
      ''
    end
  end

  def back_or_home(back_url)
    if back_url.blank?
      root_url
    else
      require 'uri'
      URI.decode(back_url)
    end
  end

  # NOTE - these next two methods replace older versions.  The old ones used "raw" html, these use haml.  If you find this is
  # causing errors, go back in time to October 12th and grab the methods.

  # def agent_logo(agent, size = "large", params={})
  #   return nil if agent.blank?
  #   src = (agent.logo_cache_url != 0) ? agent.logo_url(size) : agent.logo_file_name
  #   return src if src.empty?
  #   project_name = hh(sanitize(agent.full_name))
  #   capture_haml do
  #     haml_tag :img, {width: params[:width], height: params[:height],
  #                     src: src,  border: 0, alt: project_name,
  #                     title: project_name, class: "agent_logo"}
  #   end
  # end

  # TODO - change these methods to haml methods after conversion
  def external_link_to(*args, &block)
    #return text if link is blank
    return args[0] if args[1]==nil || args[1].blank?

    html_options = args[2] || {}
    html_options[:class] ||= ''
    html_options[:class] += ' external_link'
    html_options[:class] += ' external_link_popup' if $USE_EXTERNAL_LINK_POPUPS
    # TODO - use of target=_blank is bad for accessibility are we sure we want this? target was deprecated for xhtml but is back in html5
    html_options[:target] = '_blank'
    html_options[:title] ||= I18n.t(:target_blank_advisory_information)

    if html_options[:show_link_icon].nil? || html_options.delete(:show_link_icon) == true
      args[0] += " #{external_link_icon}"
    end
    link_to(raw(args[0]),args[1],html_options, &block)
  end

  def allow_some_html(text)
    text = text.allow_some_html
    unless text.match(/<(br|p)\s*[\/]?\s*>/)
      text.gsub!("\n", "<br/>")
    end
    text
  end

  # returns a string that can be used as a CSS class, given an object
  def css_class value
    value.to_s.strip.downcase.gsub(' ','') # TODO update to strip out all non alphanumeric characters
  end

  def unpublished_icon(options={})
    style = options[:style] ? "style=\"#{options[:style]}\"" : ''
    "<img src=\"/assets/icons/unpublished.png\" alt=\"Unpublished\" title=\"Unpublished\" #{style} />"
  end

  def published_icon(options={})
    style = options[:style] ? "style=\"#{options[:style]}\"" : ''
    description = options[:agent_name] ? "From #{options[:agent_name]}" : ''
    "<img src=\"/assets/icons/published.png\" alt=\"#{description}\" title=\"#{description}\" #{style} />"
  end

  @@TOOLTIP_GLOBAL_COUNT = 0
  def define_term(term)
    if glossary_term = GlossaryTerm.find_by_term(term)
      @@TOOLTIP_GLOBAL_COUNT += 1
      render partial: '/popups/glossary_tooltip', locals: {term: term, definition: glossary_term.definition, element_id: "tooltip_#{@@TOOLTIP_GLOBAL_COUNT}"}
    else
      return term
    end
  end

  def cancel_button_goes_back(url)
    c = I18n.t(:cancel)
    url = back_or_home(url)
    capture_haml do
      haml_tag :input, {id: "cancel", type: 'button', name: c, value: c,
                        onclick: "javascript:window.location='#{url.force_encoding('UTF-8')}';"}
    end
  end

  # NOTE - these two methods are TOTALLY DUPLICATED in application_controller....
  # Until we fix that, best to keep them perfectly in-sync
  def link_to_item(item, options = {})
    case item
    when Collection
      collection_url(item, options)
    when Community
      community_url(item, options)
    when DataObject
      data_object_url(item.latest_published_version_in_same_language || item, options)
    when User
      user_url(item, options)
    when TaxonConcept
      taxon_url(item, options)
    when UserAddedData
      options.merge!(anchor: item.anchor)
      taxon_data_url(item.taxon_concept, options)
    when DataPointUri
      options.merge!(anchor: item.anchor)
      taxon_data_url(item.taxon_concept, options)
    when Resource
      content_partner_resource_url(options[:content_partner], item)
    else
      raise EOL::Exceptions::ObjectNotFound
    end
  end
  def link_to_newsfeed(item, options = {})
    case item
    when Collection
      collection_newsfeed_url(item, options)
    when Community
      community_newsfeed_url(item, options)
    when DataObject
      data_object_url(item.latest_published_version_in_same_language || item, options)
    when User
      user_newsfeed_url(item, options)
    when TaxonConcept
      if options[:taxon_updates] # Sometimes you want to go to the long activity view for taxa...
        taxon_updates_url(item, options.delete(:taxon_updates))
      else
        taxon_url(item, options)
      end
    when UserAddedData
      options.merge!(anchor: item.anchor)
      taxon_data_url(item.taxon_concept, options)
    when DataPointUri
      options.merge!(anchor: item.anchor)
      taxon_data_url(item.taxon_concept, options)
    else
      raise EOL::Exceptions::ObjectNotFound
    end
  end

  def navigation_node(hierarchy_entry, options = {})
    return hierarchy_entry.italicized_name.firstcap if options[:current]
    options = options.select{ |k, v| [ :link_to_taxa,  :show_siblings, :show_hierarchy_label ].include?(k) }
    link = options[:link_to_taxa] ?
      taxon_overview_path(hierarchy_entry.taxon_concept_id) :
      taxon_entry_overview_path(hierarchy_entry.taxon_concept_id, hierarchy_entry)
    node = link_to(raw(hierarchy_entry.italicized_name.firstcap), link)
    node << ' '
    node << navigation_show_descendants_link(hierarchy_entry, options.reverse_merge(link: link))
  end

  def navigation_show_descendants_link(hierarchy_entry, options={})
    link = if options[:link]
      options.delete(:link)
    else
      options[:link_to_taxa] ?
        taxon_overview_path(hierarchy_entry.taxon_concept_id) :
        taxon_entry_overview_path(hierarchy_entry.taxon_concept_id, hierarchy_entry)
    end
    if hierarchy_entry.number_of_descendants == 0
      ''
    else
      open_tree_path = taxon_entry_tree_path(hierarchy_entry.taxon_concept_id, hierarchy_entry, options)
      link_to('+', link, class: 'show_tree', data_url: open_tree_path)
    end
  end

  def image_url(source)
    URI.join(root_url, image_path(source))
  end

  def show_full_tree(hierarchy_entry, options={})
    ancestors = hierarchy_entry.ancestors
    if ancestor = ancestors.shift
      # using strings here instead of haml.concat because it saves up to 30% of the processing time
      html = "<ul class='branch' id='entry_#{hierarchy_entry.id}'><li>" +
        navigation_node(ancestor, options) +
        show_full_tree(hierarchy_entry, options) +
        "</li></ul>"
      html
    else
      html = show_nodes([ hierarchy_entry ], options.merge(current: true))
      if options[:show_siblings]
        html += show_nodes(options[:siblings], options.merge(parent: hierarchy_entry.parent))
      end
      html
    end
  end

  def show_nodes(hierarchy_entries, options={})
    options[:max_children] ||= 500
    capture_haml do
      # using .nil? || == 0 here instead of .blank? because that would create a COUNT query,
      # but we need to load the data anyway, so a COUNT would be unnecessary and inefficient
      unless hierarchy_entries.nil? || hierarchy_entries.length == 0
        haml_tag :ul, class: 'branch' do
          # sort the array by name string
          # TODO: we might test wether its faster to get back ALL records from the DB then sort, or sort directly in DB
          hierarchy_entries = HierarchyEntry.sort_by_name(hierarchy_entries)
          # limit the array to $max_children and iterate
          hierarchy_entries[0...options[:max_children]].each do |hierarchy_entry|
            haml_tag :li, id: "node_#{hierarchy_entry.id}" do
              haml_tag :span, class: (options[:current] ? 'current' : nil) do
                haml_concat navigation_node(hierarchy_entry, options)
              end
              unless (options[:parent] && !options[:expand]) || hierarchy_entry.is_leaf?
                # querying for the first $max_children children, ordered by name, and preloading the name strings all at once
                children = hierarchy_entry.children.includes(:name).order('names.string').limit(options[:max_children])
                haml_concat show_nodes(children, options.reject{ |k,v| k == :current }.merge(parent: hierarchy_entry))
              end
            end
          end

          # Show a 'see more' type message
          if parent = options[:parent]
            potential_entries_to_show = parent.children.count
            if options[:max_children] < potential_entries_to_show
              haml_tag :li, class: 'show_tree_count' do
                haml_concat I18n.t(:more_children_with_count, count: potential_entries_to_show - options[:max_children])
                full_link = options[:link_to_taxa] ?
                  taxon_overview_path(parent.taxon_concept_id, full: true) :
                  taxon_entry_overview_path(parent.taxon_concept_id, parent, full: true)
                full_data_link = taxon_entry_tree_path(parent.taxon_concept_id, parent, full: true, link_to_taxa: options[:link_to_taxa],
                  show_siblings: options[:show_siblings], show_hierarchy_label: options[:show_hierarchy_label])
                haml_concat link_to(I18n.t(:show_full_tree), full_link, class: 'show_tree', data_url: full_data_link)
              end
            end
          end
        end
      end
    end
  end

  # will return the class name and label used to generate the colored box showing
  # this object's curation status: Green/Trusted, Gray/Unreviewed, Red/Untrusted, Red/Hidden
  # or if none available: nil, nil
  # NOTE - this assumes you have loaded either @taxon_page (preferred) or @taxon_concept.
  def status_class_and_label_for_data_object(data_object)
    vis = data_object.visibility_by_taxon_concept(@taxon_page || @taxon_concept)
    vet = data_object.vetted_by_taxon_concept(@taxon_page || @taxon_concept)
    if vis == Visibility.get_invisible
      return 'untrusted', I18n.t(:hidden)
    else
      # Well, shoot. We can't use #label here, because #label is translated.
      status_class = case vet
        when Vetted.unknown       then 'unknown'
        when Vetted.untrusted     then 'untrusted'
        when Vetted.trusted       then 'trusted'
        when Vetted.inappropriate then 'inappropriate'
        else nil
      end
      status_label = case vet
        when Vetted.unknown then I18n.t(:unreviewed)
        else vet.label
      end
      return status_class, status_label
    end
    return nil, nil
  end

  def time_diff(start_time, end_time)
    seconds_diff = (start_time - end_time).to_i.abs
    hours = seconds_diff / 3600
    seconds_diff -= hours * 3600
    minutes = seconds_diff / 60
    seconds_diff -= minutes * 60
    seconds = seconds_diff
    "#{hours.to_s.rjust(2, '0')}:#{minutes.to_s.rjust(2, '0')}:#{seconds.to_s.rjust(2, '0')}"
  end


  def format_time(given_seconds)
     Time.at(given_seconds).utc.strftime("%H:%M:%S")
  end

end
