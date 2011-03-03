class DataType < SpeciesSchemaModel
  
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
    $LOCAL_CACHE.data_type_text ||= cached_find(:label, 'Text')
  end
  
  def self.image
    $LOCAL_CACHE.data_type_image ||= cached_find(:label, 'Image')
  end
  
  def self.sound
    $LOCAL_CACHE.data_type_sound ||= cached_find(:label, 'Sound')
  end
  
  def self.video
    $LOCAL_CACHE.data_type_video ||= cached_find(:label, 'Video')
  end
  
  def self.youtube
    $LOCAL_CACHE.data_type_youtube ||= cached_find(:label, 'YouTube')
  end
  
  def self.flash
    $LOCAL_CACHE.data_type_flash ||= cached_find(:label, 'Flash')
  end
  
  def self.gbif_image
    $LOCAL_CACHE.data_type_gbif_image ||= cached_find(:label, 'GBIF Image')
  end
  
  def self.iucn
    $LOCAL_CACHE.data_type_iucn ||= cached_find(:label, 'IUCN')
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
      which.collect { |type| DataType.find_all_by_label(type) }.flatten.collect {|type| type.id }
    end
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: data_types
#
#  id           :integer(2)      not null, primary key
#  label        :string(255)     not null
#  schema_value :string(255)     not null

