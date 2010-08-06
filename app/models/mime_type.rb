# Represents a system mime/type.  Used by DataObject.
class MimeType < SpeciesSchemaModel
  has_many :data_objects

  def self.mp4
    MimeType.find_by_label('video/mp4')
  end
  def self.wmv
    MimeType.find_by_label('video/x-ms-wmv')
  end
  def self.mpeg
    MimeType.find_by_label('video/mpeg')
  end
  def self.mov
    MimeType.find_by_label('video/quicktime')
  end
  def self.flv
    MimeType.find_by_label('video/x-flv')
  end

  def self.get_label(mime_type_id)    
    rset = MimeType.find_by_sql(["Select mime_types.label From mime_types Where mime_types.id = #{mime_type_id}"])            
    rset.each do |rec|
      return rec.label
    end    
    return ""
  end

  def self.extension(mime_type_id)    
    label = get_label(mime_type_id)    
    if label == 'video/mp4'        
        return ".mp4"
    elsif label == 'video/x-ms-wmv'
        return ".wmv"
    elsif label == 'video/mpeg'    
        return ".mpg"        
    elsif label == 'video/quicktime'    
        return ".mov"
    elsif label == 'video/x-flv'    
        return ".flv"
    end    
  end  

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: mime_types
#
#  id    :integer(2)      not null, primary key
#  label :string(255)     not null
