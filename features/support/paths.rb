module LocationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /home\s?page/
      '/'

    when /Honey bee page/
      '/pages/1045608'

    when /Honey bee page habitat section/
      '/pages/1045608?category_id=41'

    when /dato page without taxon concept id/
      '/data_objects/2604048'
      # Add more mappings here.
      # Here is an example that pulls values out of the Regexp:
      #
      #   when /^(.*)'s profile page$/i
      #     user_profile_path(User.find_by_login($1))
    when /curation worklist page/
      '/curators/curate_images'

    else
      begin
        page_name =~ /(.*) page/
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

    when "member's name"
      [:content, "Cuke"]
    when 'title'
      [:css, "title"] # head title
    when 'page title'
      [:css, "#page-title"]
    when 'personal space'
      [:css, "#personal-space"]
    when 'login link'
      [:css, ".login_link"]
    when 'sidebar a header'
      [:css, "#sidebar-a h1"]
    when 'sidebar b header'
      [:css, "#sidebar-b h1"]
    when /^([a-z]+) tab$/
      tab_name = $1
      tab_name = "taxa-" + tab_name if tab_name == 'comments'
      [:css, "#tab_media_center ##{tab_name} a"]
    when 'table of contents'
      [:css, "#toc"]
    when /comment button (?:for the|for a|for) main image/
      [:css, '#large-image-comment-button a']
    when /comment button (?:for the|for a|for) text objects/
      [:xpath, '//*[@class="text_object"]//*[starts-with(@class, "comment_button")]/a']
    when 'comments section'
      [:css, '#commentsContain']
    when 'data object attribution'
      [:css, "#data_object_attribution"]
    when 'permalink for the data object'
      [:css, '#data_object_attribution .permalink']
    when 'data object comments'
      [:css, "#data_object_comments"]
    when 'data object status'
      [:css, "#data_object_status"]
    when 'data object content'
      [:css, "#data_object_content"]
    when 'data object image'
      [:css, '#data_object_content #data_object img']
    when 'data object curation menu'
      [:css, '#curation-overlay']
    when 'image curation icon'
      [:css, '#large-image-curator-button #large-image-curator-button-popup-link']
    when 'text data object title'
      [:css, "#text_object_title"]
    when 'text object header'
      [:css, ".cpc-header"]
    when 'text object content'
      [:css, ".cpc-content"]
    when 'add text button'
      [:css, "#new_text_content_button"]
    when 'add new content button'
      [:css, "#new_text_toc_button"]
    when 'add new content link'
      [:css, "#new_text_toc_text"]
    when 'add text panel'
      [:css, "#insert_text_popup"]
    when 'add text form'
      [:css, "#new_data_object"]
    when 'add text category field'
      [:css, "#data_objects_toc_category_toc_id"]
    when 'add text title field'
      [:css, "#data_object_object_title"]
    when 'add text description field'
      [:css, "#data_object_description"]
    when 'add text language field'
      [:css, "#data_object_language_id"]
    when 'add text license field'
      [:css, "#data_object_license_id"]
    when 'add text references field'
      [:css, "#references"]
    when 'main image icons area'
      [:css, "#large-image-buttons"]
    when 'missing text error message'
      [:css, "#missing_text_error"]
    when 'edit text link'
      [:css, ".text_object .edit_text"]
    when 'close button'
      [:css, ".close-button"]
    when 'untrusted reasons'
      [:css, ".untrust_reason"]
    when 'untrusted radio button'
      [:css, "#vetted_id_" + Vetted.untrusted.id.to_s]
    when 'misidentified untrust reason checkbox'
      [:css, "#untrust_reason_misidentified"]
    when 'other untrust reason checkbox'
      [:css, "#untrust_reason_other"]
    when 'trusted main image'
      [:css, ".main-image-bg.trusted"]
    when 'untrusted main image'
      [:css, ".main-image-bg.untrusted"]
    when 'curate content of this clade link'
      [:css, "#curation_worklist_link"]
    when 'first image box'
      [:css, "tr:nth-child(2)"]
    else
      [:css, selector]
    end
  end
end

World(LocationHelpers)
