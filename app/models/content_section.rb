class ContentSection < ActiveRecord::Base

   has_many :content_pages, :order=>'sort_order', :conditions=>'active=1'
   validates_presence_of :name
   
   # helper method to retrieve a language key equivalent to the section name if none is supplied in the database
   def key
    if self.language_key == '' || self.language_key.nil?
      return self.name.gsub(' ','_').downcase.to_sym
    else
      return self.language_key.to_sym
    end
  end
  
  # helper method to find active pages given a section name
  def self.find_pages_by_section(section_name)
    
    return ContentPage.find_all_by_content_section_id_and_language_abbr_and_active(ContentSection.find_by_name(section_name).id,'en',true,:order=>'sort_order')
   
  end
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: content_sections
#
#  id           :integer(4)      not null, primary key
#  language_key :string(255)     not null, default("")
#  name         :string(255)     not null, default("")
#  created_at   :datetime
#  updated_at   :datetime

