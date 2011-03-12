# Represents a system mime/type.  Used by DataObject.
class MimeType < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  has_many :data_objects

  def self.mp4
    cached_find(:label, 'video/mp4')
  end
  def self.wmv
    cached_find(:label, 'video/x-ms-wmv')
  end
  def self.mpeg
    cached_find(:label, 'video/mpeg')
  end
  def self.mov
    cached_find(:label, 'video/quicktime')
  end
  def self.flv
    cached_find(:label, 'video/x-flv')
  end
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: mime_types
#
#  id    :integer(2)      not null, primary key
#  label :string(255)     not null
