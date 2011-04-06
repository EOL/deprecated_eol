# Enumerated list of statuses for an Agent.  For now, mainly distinguishing between active, archived, and pending agents.
class AgentStatus < SpeciesSchemaModel
  uses_translations
  has_many :content_partners

  def self.active
    cached_find_translated(:label, 'Active')
  end

  def self.inactive
    cached_find_translated(:label, 'Inactive')
  end

end
