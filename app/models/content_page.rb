# The top nav bar of the site is geared to handle ContentSection (q.v.) sections, each of which has one or more ContentPage
# objects associated with it.  These pages are static content *or* links to external resources, and can be edited by
# administrators.
class ContentPage < $PARENT_CLASS_MUST_USE_MASTER
  #CACHE_ALL_ROWS = true
  uses_translations
  
  belongs_to :content_page, :class_name => ContentPage.to_s, :foreign_key => 'parent_content_page_id'
  
  #has_many :content_page_archives, :order => 'created_at DESC', :limit => 15
  belongs_to :user, :foreign_key => 'last_update_user_id'
  
  validates_presence_of :page_name
  before_save :remove_underscores_from_page_name
  
  def self.get_by_page_name_and_language_abbr(page_name, language_abbr)
    #set_translation_language(Language.find_by_iso_639_1(language_abbr))
    language_page = self.find_by_page_name_and_active(page_name, true)
    
    #if language_page.nil
    #  set_translation_language(Language.english)
    #  language_page = self.find_by_page_name_and_active(page_name, true)
    #end
    
    #language_page = self.find_by_page_name_and_active(page_name, true).find_by_translated(Language.english.id) if
    #  language_page.nil? # if we couldn't find that language, try English
    return language_page
    #language_page = self.find_by_page_name_and_active_and_language_id(page_name, true, Language.find_by_iso_639_1(language_abbr))
    #language_page = self.find_by_page_name_and_active_and_language_abbr(page_name, true, Language.english.id) if
    #  language_page.nil? # if we couldn't find that language, try English
    #return language_page
  end
  
  def self.get_navigation_tree(page_id)    
    if (page_id)
      content_page = ContentPage.find(page_id)
      if content_page.parent_content_page_id
        return get_navigation_tree(content_page.parent_content_page_id) + " > " + content_page.page_name + " > "
      else
        return content_page.page_name
      end
    end    
  end
  
  def self.get_navigation_tree_with_links(page_id)    
    if (page_id)
      content_page = ContentPage.find(page_id)
      if content_page.parent_content_page_id
        parent_content_page = self.find(content_page.parent_content_page_id)
        return get_navigation_tree_with_links(content_page.parent_content_page_id) + "<a href='/content/page/#{parent_content_page.id}'>" + parent_content_page.page_name + "</a> > "
      else
        return ''#content_page.page_name
      end
    end    
  end
  
  def self.find_top_level
    #return ContentPage.find_all_by_parent_content_page_id(null) # get pages where parent is null
    return ContentPage.find_all_by_parent_content_page_id(nil, :order => 'sort_order') # get pages where parent is null
  end

  def self.get_by_id_and_language_abbr(id, language_abbr)
    language = Language.find_by_iso_639_1(language_abbr)
    #self.set_translation_language(language)    
    language_page = self.find_by_id_and_active(id, true)
    #if langauge_page.nil? # No page for this language, use English
      #self.set_translation_language(Language.english)    
      #language_page = self.find_by_id_and_active(id, true)
    #end
    return language_page
  end
  
  def self.find_all_by_language_abbr_and_active(language_abbr, active)
    language = Language.find_by_iso_639_1(language_abbr)
    #self.set_translation_language(language)
    language_pages = self.find_all_by_active(true)
    if language_pages.nil? # Langauge doesn't have pages for this section, try English
      #self.set_translation_language(Language.english)
      language_pages = self.find_all_by_active(true)
    end    
    return language_pages
  end
  
  def not_available_in_languages(force_exist_language)
    if self.id
      if force_exist_language
        return Language.find_by_sql("select * from languages where (not exists (select * from translated_content_pages where language_id=languages.id and content_page_id=#{self.id}) or languages.id=#{force_exist_language.id}) and activated_on <= '#{Time.now.to_s(:db)}' order by sort_order ASC")
      else
        return Language.find_by_sql("select * from languages where (not exists (select * from translated_content_pages where language_id=languages.id and content_page_id=#{self.id})) and activated_on <= '#{Time.now.to_s(:db)}' order by sort_order ASC")
      end
    else
      return Language.find_active
    end
  end
  
  def remove_underscores_from_page_name
    self.page_name.gsub!('_', ' ')
  end
  
  # helper method to retrieve a language key equivalent to the page name if none is supplied in the database
  def key
    #if self.language_key == '' || self.language_key.nil?
    #  return self.title.gsub(' ', '_').downcase.to_sym
    #else
    #  return self.language_key.to_sym
    #end
    return ""
  end
  
  def self.update_sort_order_based_on_deleting_page(parent_content_page_id, sort_order)
    same_level_pages = ContentPage.find_all_by_parent_content_page_id(parent_content_page_id)
    for content_page in same_level_pages
      content_page.update_attribute(:sort_order, content_page.sort_order - 1) if content_page.sort_order > sort_order
    end
  end
  
  def page_url
    return self.page_name.gsub(' ', '_').downcase
  end
  
  # name to use for cached fragment
  def fragment_name
    self.content_section.key.to_s + "_" + self.key.to_s 
  end
  
end

