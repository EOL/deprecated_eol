# Associates an Angent to a Resource (q.v.) assigning a particular ResourceAgentRole.
class AgentsResource < SpeciesSchemaModel
  require 'composite_primary_keys'
  set_primary_keys :agent_id,:resource_id,:resource_agent_role_id
  
  belongs_to :resource
  belongs_to :agent
  belongs_to :resource_agent_role
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: agents_resources
#
#  agent_id               :integer(4)      not null
#  resource_agent_role_id :integer(1)      not null
#  resource_id            :integer(4)      not null

