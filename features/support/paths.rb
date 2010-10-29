module NavigationHelpers
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
    when /([a-z]+) tab/
      tab_name = $1
      tab_name = "taxa-" + tab_name if tab_name == 'comments'
      [:css, "#tab_media_center ##{tab_name} a"]
    when /([a-z]+) button (?:for the|for a|for) (.+)$/
      button_type = $1
      object = $2
      if button_type == 'comment' && object == 'main image'
        return [:css, '#large-image-comment-button a'] 
      elsif button_type == 'comment' && object == 'text objects'
        return [:xpath, '//*[@class="text_object"]//*[starts-with(@class, "comment_button")]/a']
      end
    when /([a-z]+) section/
      section_type = $1
      if section_type == "comments"
        return [:css, '#commentsContain']
      end
    when 'data object image'
      return [:css, '#data_object_content #data_object img']
    else
      [:css, selector]
    end
  end
end

World(NavigationHelpers)
