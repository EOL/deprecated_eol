# Joins an Agent to a DataObject via an AgentRole.
class AgentsDataObject < ActiveRecord::Base

  belongs_to :data_object
  belongs_to :agent
  belongs_to :agent_role
  set_primary_keys :data_object_id, :agent_id, :agent_role_id

end
