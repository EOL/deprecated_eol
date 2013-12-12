# Represents a system mime/type.  Used by DataObject.
class MimeType < ActiveRecord::Base

  uses_translations
  has_many :data_objects

  include Enumerated
  enumerated :label, [
    { jpg: 'image/jpeg' },
    { html: 'text/html' },
    { txt: 'text/plain' },
    { mp4: 'video/mp4' },
    { wmv: 'video/x-ms-wmv' },
    { mpeg: 'video/mpeg' },
    { mov: 'video/quicktime' },
    { flv: 'video/x-flv' },
    { mp3: 'audio/mpeg' },
    { wav: 'audio/x-wav' }
  ]

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
  def self.mp3
    cached_find_translated(:label, 'audio/mpeg')
  end
  def self.wav
    cached_find_translated(:label, 'audio/x-wav')
  end
  def self.ogg_video
    cached_find_translated(:label, 'application/ogg')
  end
end
