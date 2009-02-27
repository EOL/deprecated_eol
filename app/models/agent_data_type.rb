# This is not a class used in the code.  However, the data represents what content partners will be providing, which helps us
# prioritize harvests (for example, when we feel we need videos, we can find content partners promising video data).
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

