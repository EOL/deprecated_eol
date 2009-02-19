class ContentPage < ActiveRecord::Base
  
  belongs_to :content_section
  has_many :content_page_archives, :order=>'original_creation_date ASC', :limit=>15
  belongs_to :user, :foreign_key => 'last_update_user_id'
  
  validates_presence_of :main_content, :if=>:url_and_left_content_is_blank?
  validates_presence_of :url, :if=>:content_is_blank?

  validates_presence_of :content_section_id, :page_name, :title
  before_save :remove_underscores_from_page_name
  
  def title_with_language
    title + " (" + language_abbr + ")"
  end
  
  def self.get_by_page_name_and_language_abbr(page_name,language_abbr)
    language_page=self.find_by_page_name_and_active_and_language_abbr(page_name,true,language_abbr)
    language_page=self.find_by_page_name_and_active_and_language_abbr(page_name,true,Language.english.iso_639_1) if language_page.nil? # if we couldn't find that language, try English
    return language_page
  end

  def self.get_by_id_and_language_abbr(id,language_abbr)
    language_page=self.find_by_id_and_active_and_language_abbr(id,true,language_abbr)
    language_page=self.find_by_id_and_active_and_language_abbr(id,true,Language.english.iso_639_1) if language_page.nil? # if we couldn't find that language, try English
    return language_page
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
    
    self.page_name.gsub!('_',' ')
    
  end
  
  # helper method to retrieve a language key equivalent to the page name if none is supplied in the database
  def key
    if self.language_key == '' || self.language_key.nil?
      return self.title.gsub(' ','_').downcase.to_sym
    else
      return self.language_key.to_sym
    end
  end

  def page_url
    return self.page_name.gsub(' ','_').downcase
  end
  
  # name to use for cached fragment
  def fragment_name
    
    self.content_section.key.to_s + "_" + self.key.to_s 
      
  end
  
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: content_pages
#
#  id                 :integer(4)      not null, primary key
#  content_section_id :integer(4)
#  active             :boolean(1)      not null, default(TRUE)
#  language_abbr      :string(255)     not null, default("en")
#  language_key       :string(255)     not null, default("")
#  left_content       :text            not null
#  main_content       :text            not null
#  open_in_new_window :boolean(1)
#  page_name          :string(255)     not null, default("")
#  sort_order         :integer(4)      not null, default(1)
#  title              :string(255)     not null, default("")
#  url                :string(255)     default("")
#  created_at         :datetime
#  updated_at         :datetime

