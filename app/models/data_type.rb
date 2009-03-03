class DataType < SpeciesSchemaModel

  acts_as_enum

  has_many :data_objects

  class << self
    attr_accessor :attribution_order
    def attribution_order
      # define defaults 
      @attribution_order ||= {
        'Image' => AgentRole[ :Author, :Source, :Project, :Publisher ],
        'Text' => AgentRole[ :Author, :Source, :Project, :Publisher ]
      }
    end
  end

  # shortcut reference to DataType.attribution_order[ @data_type.label ]
  def attribution_order
    self.class.attribution_order[ self.label ] ||= []
  end

  def attribution_order_for agent_role
    agent_role_id = (agent_role.is_a?Fixnum) ? agent_role : agent_role.id
    full_attribution_order.each_with_index do |ordered_agent_role, index|
      return index if ordered_agent_role.id == agent_role_id
    end
    return -1 # doesn't exist!
  end

  def full_attribution_order
    other_roles = AgentRole.all - attribution_order
    attribution_order + other_roles
  end
  
  def self.image_type_ids
    Rails.cache.fetch(:image_type_ids) do
      DataType.get_type_ids(['Image'])
    end
  end
  
  def self.video_type_ids
    Rails.cache.fetch(:video_type_ids) do
      DataType.get_type_ids(['YouTube', 'Flash'])
    end
  end

  def self.map_type_ids
    Rails.cache.fetch(:map_type_ids) do
      DataType.get_type_ids(['GBIF Image'])
    end
  end

  def self.text_type_ids
    Rails.cache.fetch(:text_type_ids) do
      DataType.get_type_ids(['Text'])
    end
  end

private
  def self.get_type_ids(which)
    return which.collect { |type| DataType.find_all_by_label(type) }.flatten.collect {|type| type.id }
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

