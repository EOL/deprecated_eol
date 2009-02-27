# An enumerated list of the different kinds of roles an Agent fills.
class AgentRole < SpeciesSchemaModel

  acts_as_enum

  has_many :agents_data_objects
  
  # Find the "Source" AgentRole.
  def self.source_id
    @@source_id ||= AgentRole.find_by_label('Source').id
  end
  
  # Find the "Author" AgentRole.
  def self.author_id
    @@author_id ||= AgentRole.find_by_label('Author').id
  end
  
  # Find the "Photographer" AgentRole.
  def self.photographer_id
    @@photographer_id ||= AgentRole.find_by_label('Photographer').id
  end
    
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: agent_roles
#
#  id    :integer(1)      not null, primary key
#  label :string(100)     not null
