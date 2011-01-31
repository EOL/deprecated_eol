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
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: mime_types
#
#  id    :integer(2)      not null, primary key
#  label :string(255)     not null
