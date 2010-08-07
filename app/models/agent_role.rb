# An enumerated list of the different kinds of roles an Agent fills.
class AgentRole < SpeciesSchemaModel

  has_many :agents_data_objects
  has_many :agents_synonyms

  def to_s
    label
  end

  def self.attribution_order
    labels = [ :Author, :Source, :Project, :Publisher ]
    labels.map {|l| AgentRole.find_by_label(l.to_s) }
  end
  
  # Find the Author
  def self.author
    CACHE.fetch('agent_roles/author') do
      AgentRole.find_by_label('Author')
    end
  end
  
  # Find the Source
  def self.source
    CACHE.fetch('agent_roles/source') do
      AgentRole.find_by_label('Source')
    end
  end
  
  # Find the "Source" AgentRole.
  def self.source_id
    AgentRole.source.id
  end
  
  # Find the "contributor" AgentRole.
  def self.contributor_id
    CACHE.fetch('agent_roles/contributor_id') do
      AgentRole.find_by_label('Contributor').id
    end
  end
  
  # Find the "Author" AgentRole.
  def self.author_id
    AgentRole.author.id
  end
  
  # Find the "Photographer" AgentRole.
  def self.photographer_id
    CACHE.fetch('agent_roles/photographer_id') do
      AgentRole.find_by_label('Photographer').id
    end
  end
    
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: agent_roles
#
#  id    :integer(1)      not null, primary key
#  label :string(100)     not null

