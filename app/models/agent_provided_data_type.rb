class AgentProvidedDataType < SpeciesSchemaModel
  belongs_to :agent
  belongs_to :agent_data_type
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: agent_provided_data_types
#
#  agent_data_type_id :integer(4)      not null
#  agent_id           :integer(4)      not null

