class DataType < ActiveRecord::Base
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :data_objects
  @@full_attribution_order = nil

  def to_s
    label
  end

  def video_label
    return "flash" if self == DataType.youtube
    return label.downcase
  end

  def self.full_attribution_order
    return @@full_attribution_order if !@@full_attribution_order.nil?
    # this is the order in which agents will be attributed
    attribution_order = AgentRole.attribution_order
    remaining_roles = AgentRole.all - attribution_order
    @@full_attribution_order = attribution_order + remaining_roles
  end

  def self.text
    cached_find_translated(:label, 'Text')
  end

  def self.image
    cached_find_translated(:label, 'Image')
  end

  def self.sound
    cached_find_translated(:label, 'Sound')
  end

  def self.video
    cached_find_translated(:label, 'Video')
  end

  # TODO -this is essentially "SWF" and could be handled as Video...
  def self.youtube
    cached_find_translated(:label, 'YouTube')
  end

  # TODO -this is essentially "SWF" and could be handled as Video...
  def self.flash
    cached_find_translated(:label, 'Flash')
  end

  def self.iucn
    cached_find_translated(:label, 'IUCN')
  end
  
  def self.map
    cached_find_translated(:label, 'Map')
  end
  

  def self.sound_type_ids
    ids = [DataType.sound.id]
  end

  def self.image_type_ids
    ids = [DataType.image.id]
  end

  def self.video_type_ids
    ids = [DataType.youtube.id, DataType.flash.id, DataType.video.id]
  end

  def self.text_type_ids
    ids = [DataType.text.id]
  end
  
  def self.map_type_ids
    ids = [DataType.map.id]
  end
  

  # Not all unique data types DISPLAY with their label... translations come from the DB on the labels we know we
  # like:
  def simple_type(language_iso_code = nil)
    if DataType.image_type_ids.include? id
      DataType.image.label(language_iso_code)
    elsif DataType.text_type_ids.include? id
      DataType.text.label(language_iso_code)
    elsif DataType.sound_type_ids.include? id
      DataType.sound.label(language_iso_code)
    elsif DataType.video_type_ids.include? id
      DataType.video.label(language_iso_code)
    else
      label(language_iso_code) # We'll have to use whatever we have.
    end
  end

end
