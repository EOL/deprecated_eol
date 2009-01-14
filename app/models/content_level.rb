class ContentLevel
  
  # class to represent content levels available in the system
  
  attr_reader :id,:name,:short_name
    
  def initialize(id,name,short_name)
    @id=id
    @name=name
    @short_name=short_name
  end
  
  def self.description_by_id(id)
    
    # list of content level IDs on specific page banner to user
    case id.to_s
      when "1": return "Minimal Page"[]
      when "2","3", "4": return ""
    end
        
  end
  
  def self.find()
    
    # list of content codes for drop-down menu
    list=Array.new

    list << self.new('1',"All pages"[],"All pages"[])
  #  list << self.new('2',"View only pages with at least a picture or piece of text"[],"Pages with pictures or text"[])
    list << self.new('4',"Just those pages with pictures and text"[:just_pages_with_pictures_and_text],"Pages with pictures and text"[:pages_with_pictures_and_text])
    
    return list
    
  end
  
end