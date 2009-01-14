class AgentDataType < SpeciesSchemaModel
  has_many :agent_provided_data_types
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: agent_data_types
#
#  id    :integer(1)      not null, primary key
#  label :string(100)     not null

