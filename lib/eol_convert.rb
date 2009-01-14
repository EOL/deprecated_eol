class EOLConvert
  
  # places the hash into an array if there is only one element
  #   this allows us to have a consistent hashed array representation for any collection even if it only has one item
  def self.convert_to_hashed_array(hashed)
      
      if hashed.class == Hash # next check if our output is still a hash
        hashed_array=Array.new # if so, drop it into a one element array
        hashed_array << hashed
        return hashed_array
      else
        return hashed
      end
   
  end    

  # pass in a search type (currently "tag" or "text") and return either tag or text --- if nil or anything other than those two things are passed in, return "text"
  def self.get_search_type(search_type)
    search_type = (search_type.blank? ? 'text' : search_type)
    search_type='text' unless ['tag','text'].include?(search_type.downcase)
    return search_type
  end
     
  # convert a boolean true/false to a 1/0 integer
    def self.boolean_to_integer(boolean_value)
 
      case boolean_value
        when true,"true","1",1
          return 1
        when false,"false","0",0 
          return 0
        else 
          return 0
      end
      
  end
  
  # convert an integer (0/1) or string to false/true boolean
  def self.to_boolean(input_value)
    
      case input_value.to_s
        when "1","true"
            return true
        when "0","false"
            return false
        else
            return false
      end
      
  end
  
end