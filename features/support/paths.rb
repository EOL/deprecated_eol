module LocationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /the home\s?page/
      '/'

    when /Honey bee page/
      '/pages/1045608?category_id=41'

    when /dato page without taxon concept id/
      '/data_objects/2604048'
      # Add more mappings here.
      # Here is an example that pulls values out of the Regexp:
      #
      #   when /^(.*)'s profile page$/i
      #     user_profile_path(User.find_by_login($1))

    else
      begin
        page_name =~ /the (.*) page/
          path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue Object => e
        page_name
        # raise "Can't find mapping from \\"#{page_name}\\" to a path.\\n" +
        #   "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end

  def get_selector(selector)
    case selector
    when 'page title'
      [:css, "#page-title"]
    when 'data object attribution'
      [:css, "#data_object_attribution"]
    when 'data object comments'
      [:css, "#data_object_comments"]
    when 'data object content'
      [:css, "#data_object_content"]
    when 'data object status'
      [:css, "#data_object_status"]
    when 'text data object title'
      [:css, "#text_object_title"]
    when 'personal space'
      [:css, "#personal-space"]
    when 'sidebar a header'
      [:css, "#sidebar-a h1"]
    when 'sidebar b header'
      [:css, "#sidebar-b h1"]
    when 'title'
      [:css, "title"] # head title
    when /([a-z]+) tab/
      tab_name = $1
      tab_name = "taxa-" + tab_name if tab_name == 'comments'
      [:css, "#tab_media_center ##{tab_name} a"]
    when /([a-z]+) button (?:for the|for a|for) (.+)$/
      button_type = $1
      object = $2
      if button_type == 'comment' && object == 'main image'
        [:css, '#large-image-comment-button a'] 
      elsif button_type == 'comment' && object == 'text objects'
        [:xpath, '//*[@class="text_object"]//*[starts-with(@class, "comment_button")]/a']
      end
    when 'comments section'
      [:css, '#commentsContain']
    when 'data object image'
      [:css, '#data_object_content #data_object img']
    when 'permalink for the data object'
      [:css, '#data_object_attribution .permalink']
    else
      [:css, selector]
    end
  end
end

World(LocationHelpers)
