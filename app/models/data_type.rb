class DataType < SpeciesSchemaModel
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
  
  def self.youtube
    cached_find_translated(:label, 'YouTube')
  end
  
  def self.flash
    cached_find_translated(:label, 'Flash')
  end
  
  def self.gbif_image
    cached_find_translated(:label, 'GBIF Image')
  end
  
  def self.iucn
    cached_find_translated(:label, 'IUCN')
  end
  
  def self.image_type_ids
    ids = [DataType.image.id]
  end
  
  def self.video_type_ids
    ids = [DataType.youtube.id, DataType.flash.id, DataType.video.id]
  end

  def self.map_type_ids
    ids = [DataType.gbif_image.id]
  end

  def self.text_type_ids
    ids = [DataType.text.id]
  end

private
  def self.get_type_ids(which)
    cached("data_types/ids/#{which.join('+').gsub(' ','_')}") do
      which.collect { |type| DataType.cached_find_translated(:label, type) }.collect {|type| type.id }
    end
  end

end
