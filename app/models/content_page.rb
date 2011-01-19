# The top nav bar of the site is geared to handle ContentSection (q.v.) sections, each of which has one or more ContentPage
# objects associated with it.  These pages are static content *or* links to external resources, and can be edited by
# administrators.
parent_klass = $CRITICAL_MODEL_PARENT_CLASS ? $CRITICAL_MODEL_PARENT_CLASS : ActiveReload::MasterDatabase rescue ActiveRecord::Base
class ContentPage < parent_klass
  
  belongs_to :content_section
  has_many :content_page_archives, :order => 'created_at DESC', :limit => 15
  belongs_to :user, :foreign_key => 'last_update_user_id'
  
  validates_presence_of :main_content, :if => :url_and_left_content_is_blank?
  validates_presence_of :url, :if => :content_is_blank?

  validates_presence_of :content_section_id, :page_name, :title
  before_save :remove_underscores_from_page_name
  
  def self.get_by_page_name_and_language_abbr(page_url, language_abbr)
    page_name = ContentPage.page_url_to_page_name(page_url)
    language_page = self.find_by_page_name_and_active_and_language_abbr(page_name, true, language_abbr)
    language_page = self.find_by_page_name_and_active_and_language_abbr(page_name, true, Language.english.iso_639_1) if
      language_page.nil? # if we couldn't find that language, try English
    return language_page
  end

  def self.get_by_id_and_language_abbr(id, language_abbr)
    language_page = self.find_by_id_and_active_and_language_abbr(id, true, language_abbr)
    language_page = self.find_by_id_and_active_and_language_abbr(id, true, Language.english.iso_639_1) if
      language_page.nil? # if we couldn't find that language, try English
    return language_page
  end
  
  def self.string_to_page_url(str)
    return '' if str.nil?
    str.clone.underscore_non_word_chars.downcase
  end

  def self.page_url_to_page_name(str)
    return '' if str.nil?
    str.clone.gsub!('_', ' ')
  end

  def title_with_language
    title + " (" + language_abbr + ")"
  end
  
  def url_and_left_content_is_blank?
    self.url.blank? && self.left_content.blank?
  end

  def content_is_blank?
    self.main_content.blank? && self.left_content.blank?
  end

  def left_content_is_blank?
    self.left_content.blank?
  end
  
  def remove_underscores_from_page_name
    self.page_name = ContentPage.page_url_to_page_name(self.page_name)
  end
  
  # helper method to retrieve a language key equivalent to the page name if none is supplied in the database
  def key
    if self.language_key == '' || self.language_key.nil?
      return self.title.gsub(' ', '_').downcase.to_sym
    else
      return self.language_key.to_sym
    end
  end

  def page_url
    return ContentPage.string_to_page_url(self.page_name)
  end
  
  # name to use for cached fragment
  def fragment_name
    self.content_section.key.to_s + "_" + self.key.to_s 
  end
  
end

