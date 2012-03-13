class AgentsSynonym < ActiveRecord::Base
  belongs_to :agent
  belongs_to :agent_role
  belongs_to :synonym
end
