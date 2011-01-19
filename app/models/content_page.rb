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
  
  def self.smart_find_with_language(id, language_abbr)
    page = nil
    default_language_abbr = Language.english.iso_639_1
    if id.is_int?
      page = self.find_by_id_and_active_and_language_abbr(id, true, language_abbr)
      page = self.find_by_id_and_active_and_language_abbr(id, true, default_language_abbr) if page.nil?
    else # assume it's a page name
      page_name = id.gsub('_', ' ')
      page = self.find_by_page_name_and_active_and_language_abbr(page_name, true, language_abbr)
      page = self.find_by_page_name_and_active_and_language_abbr(page_name, true, default_language_abbr) if page.nil?
    end
    return page
  end
  
  def self.string_to_page_url(str)
    return '' if str.nil?
    str.clone.underscore_non_word_chars.downcase
  end

  def self.home(lang_abbr = nil)
    lang_abbr ||= Language.english.iso_639_1
    self.find_by_page_name_and_active_and_language_abbr('Home', true, lang_abbr)
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
    self.page_name.gsub!('_', ' ')
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

