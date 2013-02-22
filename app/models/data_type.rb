class DataType < ActiveRecord::Base
  uses_translations
  has_many :data_objects
  @@full_attribution_order = nil

  def self.create_defaults
    [{:label => 'Image', :schema_value => 'http://purl.org/dc/dcmitype/StillImage'},
     {:label => 'Sound', :schema_value => 'http://purl.org/dc/dcmitype/Sound'},
     {:label => 'Text',  :schema_value => 'http://purl.org/dc/dcmitype/Text'},
     {:label => 'Video', :schema_value => 'http://purl.org/dc/dcmitype/MovingImage'},
     {:label => 'GBIF Image'},
     {:label => 'IUCN'},
     {:label => 'Flash'},
     {:label => 'YouTube'},
     {:label => 'Map'},
     {:label => 'Link'}].each do |default|
      trans = TranslatedDataType.find_by_label_and_language_id(default[:label], Language.default.id)
      next if trans && trans.data_type # Already there.
      dt = DataType.create(:schema_value => default[:schema_value] || default[:label])
      if trans && ! trans.data_type
        trans.data_type = dt
        trans.save
      else
        TranslatedDataType.create(:label => default[:label], :data_type => dt, :language => Language.default)
      end
    end
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
  
  def self.link
    cached_find_translated(:label, 'Link')
  end

  def self.sound_type_ids
    @@sound_type_ids ||= [DataType.sound.id]
  end

  def self.image_type_ids
    @@image_type_ids ||= [DataType.image.id]
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
