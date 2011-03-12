# We allow multiple "kinds" of AgentContact relationships.  Primary Contact is the only role that is used within the code: the
# rest are for the convenience of administrators.
class AgentContactRole < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  has_many :agent_contacts
  
  def self.primary
    cached_find(:label, 'Primary Contact')
  end
  
end
