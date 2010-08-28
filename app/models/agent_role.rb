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
    cached_find(:label, 'Author')
  end
  
  # Find the Source
  def self.source
    cached_find(:label, 'Source')
  end
  
  # Find the "Source" AgentRole.
  def self.source_id
    AgentRole.source.id
  end
  
  # Find the "contributor" AgentRole.
  def self.contributor_id
    cached_find(:label, 'Contributor').id
  end
  
  # Find the "Author" AgentRole.
  def self.author_id
    AgentRole.author.id
  end
  
  # Find the "Photographer" AgentRole.
  def self.photographer_id
    cached_find(:label, 'Photographer').id
  end
    
end
