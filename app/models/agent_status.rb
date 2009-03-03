# Enumerated list of statuses for an Agent.  For now, mainly distinguishing between active, archived, and pending agents.
class AgentStatus < SpeciesSchemaModel
  
  has_many :content_partners
    
  # Find the "Active" AgentStatus.
  def self.active
    Rails.cache.fetch(:active_agent_status) do
      AgentStatus.find_by_label('Active') 
    end
  end 
  
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: agent_statuses
#
#  id    :integer(1)      not null, primary key
#  label :string(100)     not null

