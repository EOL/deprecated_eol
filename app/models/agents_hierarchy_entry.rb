# Associates an Agent with a HierarchyEntry while assigning an AgentRole.
class AgentsHierarchyEntry < ActiveRecord::Base

  belongs_to :hierarchy_entry
  belongs_to :agent
  belongs_to :agent_role

end
