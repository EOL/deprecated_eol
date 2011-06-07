class ContentSection < ActiveRecord::Base
   CACHE_ALL_ROWS = true
   uses_translations
      
   has_many :content_pages, :order=>'sort_order', :conditions=>'active=1'   
   
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
    content_section =  find_by_translated(:name, section_name)
    return [] unless content_section
    return cached(section_name) do
      ContentPage.find_all_by_content_section_id_and_language_abbr_and_active(
        content_section.id, 'en', true, :order => 'sort_order'
      )
    end
  end
  
end
