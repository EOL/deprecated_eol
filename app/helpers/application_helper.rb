module ApplicationHelper

  def navigation_node(hierarchy_entry, opts = {})
    link = opts[:link_to_taxa] ?
      overview_taxon_path(hierarchy_entry.taxon_concept_id) :
      overview_taxon_entry_path(hierarchy_entry.taxon_concept_id, hierarchy_entry)
    node = link_to(raw(hierarchy_entry.italicized_name.firstcap), link)
    node << ' '
    node << navigation_show_descendants_link(hierarchy_entry, opts.reverse_merge(:link => link))
  end

  def navigation_show_descendants_link(hierarchy_entry, opts = {})
    link = if opts[:link]
             opts.delete(:link)
           else
             opts[:link_to_taxa] ?
             overview_taxon_path(hierarchy_entry.taxon_concept_id) :
             overview_taxon_entry_path(hierarchy_entry.taxon_concept_id, hierarchy_entry)
           end
    if hierarchy_entry.number_of_descendants == 0
      ''
    else
      open_tree_path = taxon_entry_tree_path(hierarchy_entry.taxon_concept_id, hierarchy_entry, opts)
      link_to('+', link, :class => 'show_tree', :data_url => open_tree_path)
    end
  end

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
      if errors_on?(method)
        (options[:class] = "#{options[:class].to_s} errors").strip!
        (options[:title] = "#{options[:title].to_s} #{I18n.t(:form_validation_errors_for_attribute_assistive)}").strip!
        errors = errors_for_method(@object, method)
      end

      if block_given?
        @template.concat(@template.content_tag(:label, "#{@template.capture(&block)} #{errors.to_s}".html_safe, options))
      else
        "#{super(method, content_or_options_with_block, options)} #{errors}".html_safe
      end
    end

    # tags can include :all, :minimal (default) or a comma separated string of tags
    def allowed_html_help_tip(tags = :minimal)
      return nil
      tags = "p, em, strong, a, ul, ol, li" if tags.to_sym == :minimal
      tags = "p, em, strong, a, ul, ol, li, table, tr, td" if tags.to_sym == :all
      return I18n.t(:allowed_html_tags, :comma_separated_tags => tags)
    end

    private

    def errors_on?(method)
      @object.respond_to?(:errors) && @object.errors.respond_to?(:on) && ! @object.errors[method.to_sym].blank?
    end

    def errors_for_method(object, method)
      return unless errors_on?(method)
      errors = object.errors[method.to_sym]
      if errors.any?
        errors = [errors] if errors.is_a? String
        @template.content_tag(:span, { :class => 'errors' }){ errors.join(", ") }
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
      message ||= I18n.t('activerecord.errors.template.header', :count => resource.errors.size, :model => '')
      capture_haml do
        haml_tag 'fieldset#errors' do
          haml_tag :legend, message
          haml_tag :ul do
            resource.errors.full_messages.each do |error|
              haml_tag :li, error
            end
          end
        end
      end
    end
  end

  # Used in V2 to return class for active navigation tabs.
  def resource_is_active(action)
    (controller.action_name == action.to_s || controller.class.to_s.downcase =~ /#{action}/) ? 'active' : nil
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
      en_type(object.object)
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
      I18n.t("#{en_type}_of_taxon", :taxon_name => title)
    else
      I18n.t("item_type_#{en_type}_assistive", :taxon_name => title)
    end
  end

  # A little onclick magic to make Ajaxy-links work before the page is fully loaded.  JS in the application.js file will
  # handle all the rest after the page is fully loaded (because of the class added to the link).
  # Use it like this:
  #   link_to( I18n.t(:text) , "#", :class => 'ajax_delay_click', :onclick => ajax_delay_click)
  def ajax_delay_click
    %Q{javascript:$(this).addClass('delayed_click');$('#ajax-indicator').fadeIn();return false;}
  end

  def ajax_spinner
    image_tag("indicator_arrows_black.gif", :alt =>  I18n.t(:please_wait) , :class => 'hidden spinner')
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
    image_tag('external_link.png',{ :alt => I18n.t(:external_link_icon_alt_text) })
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
  def stylesheet_include_i18n(stylesheet, options = {})
    read_stylesheet_packages unless @stylesheet_packages
    raise "** UNKNOWN STYLESHEET LOADED: #{stylesheet}" unless @stylesheet_packages.has_key?(stylesheet.to_s)
    code = ''
    if I18n.locale.to_s == 'ar' # Annoying that I have to check this, but c'est la vie. (See what I did there?)
      @stylesheet_packages[stylesheet.to_s].each do |file|
        language_stylesheet = "/languages/#{I18n.locale}/#{file}.css" # These are *replacements*
        if File.exists?(File.join(RAILS_ROOT, "public", language_stylesheet))
          code += stylesheet_link_tag(language_stylesheet, options)
        end
      end
    else
      code += stylesheet_link_merged(*[stylesheet, options])
      @stylesheet_packages[stylesheet.to_s].each do |file| # These are *additions*
        language_stylesheet = "/stylesheets/#{file}-#{I18n.locale}.css"
        if File.exists?(File.join(RAILS_ROOT, "public", language_stylesheet))
          code += stylesheet_link_tag(language_stylesheet, options)
        end
      end
    end
    return code
  end

  def read_stylesheet_packages
    array_of_hashes = YAML::load(File.open(File.join(RAILS_ROOT, 'config', 'asset_packages.yml')))['stylesheets']
    # Oddly, this gem requires the packages to be in array of hashes with a single key.  [shrug]  Clean up:
    @stylesheet_packages = {}
    array_of_hashes.each do |hsh|
      hsh.keys.each do |k|
        @stylesheet_packages[k] = hsh[k]
      end
    end
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

      # <custom>
      # Invert the default error messages so we can look them up easily for translation
      default_error_messages_inverted = ActiveRecord::Errors.default_error_messages.invert

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
          error_index = default_error_messages_inverted[error_default]

          # TODO: Gibberish translation which doesn't work anymore
          # error = error_translate["validation_#{error_index}".to_sym, *error_attributes]

          if error =~ /^\^/
            error_display = error[1..-1]
          else
            error_display =  "#{field == 'Base' ? '' : field} #{error}"
          end

          content_tag(:li,error_display)
        end
      end

      # </custom>

      contents = ''
      contents << content_tag(options[:header_tag] || :h2, options[:header_message]) unless options[:header_message].blank?
      contents << content_tag(:p, options[:message]) unless options[:message].blank?
      contents << content_tag(:ul, error_messages)

      content_tag(:div, contents, html)
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

  def agent_logo(agent, size = "large", params={})
    return nil if agent.blank?
    src = (agent.logo_cache_url != 0) ? agent.logo_url(size) : agent.logo_file_name
    return src if src.empty?
    project_name = hh(sanitize(agent.full_name))
    capture_haml do
      haml_tag :img, {:width => params[:width], :height => params[:height],
                      :src => src,  :border => 0, :alt => project_name,
                      :title => project_name, :class => "agent_logo"}
    end
  end

  # TODO - change these methods to haml methods after conversion
  def external_link_to(*args, &block)
    #return text if link is blank
    return args[0] if args[1]==nil || args[1].blank?

    html_options = args[2] || {}
    html_options[:class] ||= ''
    html_options[:class] += ' external_link'
    html_options[:class] += ' external_link_popup' if $USE_EXTERNAL_LINK_POPUPS
    # TODO - use of target=_blank is bad for accessibility are we sure we want this? target was deprecated for xhtml but is back in html5
    html_options[:target] = '_blank' # YOU WERE HERE ... make sure this works.
    html_options[:title] ||= I18n.t(:target_blank_advisory_information)

    if html_options[:show_link_icon].nil? || html_options.delete(:show_link_icon) == true
      args[0] += " #{external_link_icon}"
    end
    link_to(args[0],args[1],html_options, &block)
  end

  def allow_some_html(text)
    text = text.allow_some_html
    unless text.match(/<(br|p)\s*[\/]?\s*>/)
      text.gsub!("\n", "<br/>")
    end
    text
  end

  # for creating a group of image buttons
  #
  # Usage:
  #   <% image_button_group 'some-buttons' do |group| %>
  #     <%= group.image_button 'button1', '/some/path' %>
  #     <%= group.image_button 'button2', '/some/path' %>
  #   <% end %>
  #
  # This renders the shared/_image_button_group partial (for the whole group)
  # and, for each image_button, it renders the shared/_image_button partial
  #
  def image_button_group name, &block
    group        = ImageButtonGroup.new name, self
    buttons_html = capture(group, &block)
    group_html   = capture(group) do
      render :partial => 'shared/image_button_group', :locals => { :group => group, :buttons_html => buttons_html }
    end
    concat group_html, block.binding
  end

  # class used for an image_button_group
  #
  # when you say <%= group.image_button %> you're calling #image_button
  # on an instance of ImageButtonGroup
  #
  class ImageButtonGroup
    attr_accessor :name
    def initialize name, action_view
      @name = name
      @action_view = action_view
    end
    def image_button name, path
      # "image_button group #{@name}, #{name} => #{path}"
      @action_view.render :partial => 'shared/image_button', :locals => { :group => self, :name => name, :path => path }
    end
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
      render :partial => '/popups/glossary_tooltip', :locals => {:term => term, :definition => glossary_term.definition, :element_id => "tooltip_#{@@TOOLTIP_GLOBAL_COUNT}"}
    else
      return term
    end
  end

  def cancel_button_goes_back(url)
    c = I18n.t(:cancel)
    url = back_or_home(url)
    capture_haml do
      haml_tag :input, {:id => "cancel", :type => 'button', :name => c, :value => c,
                        :onclick => "javascript:window.location='#{url}';"}
    end
  end

  def link_to_item(item, options = {})
    case item.class.name
    when 'Collection'
      collection_url(item, options)
    when 'Community'
      community_url(item, options)
    when 'DataObject'
      data_object_url(item, options)
    when 'User'
      user_url(item, options)
    when 'TaxonConcept'
      taxon_url(item, options)
    else
      raise EOL::Exceptions::ObjectNotFound
    end
  end
  def link_to_newsfeed(item, options = {})
    case item.class.name
    when 'Collection'
      collection_newsfeed_url(item, options)
    when 'Community'
      community_newsfeed_url(item, options)
    when 'DataObject'
      data_object_url(item, options)
    when 'User'
      user_newsfeed_url(item, options)
    when 'TaxonConcept'
      taxon_url(item, options)
    else
      raise EOL::Exceptions::ObjectNotFound
    end
  end

  def navigation_node(hierarchy_entry, opts = {})
    link = opts[:link_to_taxa] ?
      taxon_overview_path(hierarchy_entry.taxon_concept_id) :
      taxon_hierarchy_entry_overview_path(hierarchy_entry.taxon_concept_id, hierarchy_entry)
    node = link_to(hierarchy_entry.italicized_name.firstcap, link)
    node << ' '
    node << navigation_show_descendants_link(hierarchy_entry, opts.reverse_merge(:link => link))
  end

  def navigation_show_descendants_link(hierarchy_entry, opts = {})
    link = if opts[:link]
             opts.delete(:link)
           else
             opts[:link_to_taxa] ?
             taxon_overview_path(hierarchy_entry.taxon_concept_id) :
             taxon_hierarchy_entry_overview_path(hierarchy_entry.taxon_concept_id, hierarchy_entry)
           end
    if hierarchy_entry.number_of_descendants == 0
      ''
    else
      open_tree_path = taxon_hierarchy_entry_tree_path(hierarchy_entry.taxon_concept_id, hierarchy_entry, opts)
      link_to('+', link, :class => 'show_tree', :data_url => open_tree_path)
    end
  end

end
