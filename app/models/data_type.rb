class DataType < ActiveRecord::Base

  uses_translations

  has_many :data_objects
  @@full_attribution_order = nil

  include Enumerated
  enumerated :label, [ 'Text', 'Image', 'Sound', 'Video', 'GBIF Image', 'YouTube', 'Flash', 'IUCN', 'Map', 'Link' ]

  def self.create_enumerated
    enumeration_creator(
      image:      { schema_value: 'http://purl.org/dc/dcmitype/StillImage' },
      sound:      { schema_value: 'http://purl.org/dc/dcmitype/Sound' },
      text:       { schema_value: 'http://purl.org/dc/dcmitype/Text' },
      video:      { schema_value: 'http://purl.org/dc/dcmitype/MovingImage' },
      gbif_image: { schema_value: 'GBIF Image' },
      iucn:       { schema_value: 'IUCN' },
      flash:      { schema_value: 'Flash' },
      youtube:    { schema_value: 'YouTube' },
      map:        { schema_value: 'Map' },
      link:       { schema_value: 'Link' }
    )
  end

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

  def self.sound_type_ids
    @@sound_type_ids ||= [DataType.sound.id]
  end

  def self.image_type_ids
    @@image_type_ids ||= [DataType.image.id]
  end

  def self.media_type_ids
    @@media_type_ids ||= sound_type_ids + image_type_ids + video_type_ids +
      map_type_ids
  end

  def self.video_type_ids
    @@video_type_ids ||= [DataType.youtube.id, DataType.flash.id, DataType.video.id]
  end

  def self.text_type_ids
    @@text_type_ids ||= [DataType.text.id]
  end

  def self.map_type_ids
    @@map_type_ids ||= [DataType.map.id]
  end

  def self.link_type_ids
    @@link_type_ids ||= [DataType.link.id]
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
