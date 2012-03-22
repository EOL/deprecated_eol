# Represents a system mime/type.  Used by DataObject.
class MimeType < ActiveRecord::Base
  uses_translations
  has_many :data_objects

  def self.mp4
    cached_find_translated(:label, 'video/mp4')
  end
  def self.wmv
    cached_find_translated(:label, 'video/x-ms-wmv')
  end
  def self.mpeg
    cached_find_translated(:label, 'video/mpeg')
  end
  def self.mov
    cached_find_translated(:label, 'video/quicktime')
  end
  def self.flv
    cached_find_translated(:label, 'video/x-flv')
  end
end
