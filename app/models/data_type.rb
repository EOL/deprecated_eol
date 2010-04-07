class DataType < SpeciesSchemaModel
  
  acts_as_enum
  
  has_many :data_objects
  @@full_attribution_order = nil
  
  def self.full_attribution_order
    return @@full_attribution_order if !@@full_attribution_order.nil?
    # this is the order in which agents will be attributed
    attribution_order = AgentRole[ :Author, :Source, :Project, :Publisher ]
    remaining_roles = AgentRole.all - attribution_order
    @@full_attribution_order = attribution_order + remaining_roles
  end
  
  def self.text
    Rails.cache.fetch('data_type/text') do
      DataType.find_by_label('Text')
    end
  end
  
  def self.image
    Rails.cache.fetch('data_type/image') do
      DataType.find_by_label('Image')
    end
  end
  
  def self.sound
    Rails.cache.fetch('data_type/sound') do
      DataType.find_by_label('Sound')
    end
  end
  
  def self.video
    Rails.cache.fetch('data_type/video') do
      DataType.find_by_label('Video')
    end
  end
  
  def self.youtube
    Rails.cache.fetch('data_type/youtube') do
      DataType.find_by_label('YouTube')
    end
  end
  
  def self.flash
    Rails.cache.fetch('data_type/flash') do
      DataType.find_by_label('Flash')
    end
  end
  
  def self.gbif_image
    Rails.cache.fetch('data_type/gbif_image') do
      DataType.find_by_label('GBIF Image')
    end
  end
  
  def self.iucn
    Rails.cache.fetch('data_type/iucn') do
      DataType.find_by_label('IUCN')
    end
  end
  
  
  
  def self.image_type_ids
    ids = [DataType.image.id]
  end
  
  def self.video_type_ids
    ids = [DataType.youtube.id, DataType.flash.id]
  end

  def self.map_type_ids
    ids = [DataType.gbif_image.id]
  end

  def self.text_type_ids
    ids = [DataType.text.id]
  end

private
  def self.get_type_ids(which)
    Rails.cache.fetch("data_types/ids/#{which.join('+').gsub(' ','_')}") do
      return which.collect { |type| DataType.find_all_by_label(type) }.flatten.collect {|type| type.id }
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

