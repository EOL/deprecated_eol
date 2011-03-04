# Enumerated list of statuses for an Agent.  For now, mainly distinguishing between active, archived, and pending agents.
class AgentStatus < SpeciesSchemaModel
  
  has_many :content_partners
    
  def self.active
    cached_find(:label, 'Active')
  end 

  def self.inactive
    cached_find(:label, 'Inactive')
  end 
  
end
