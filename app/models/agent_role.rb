# An enumerated list of the different kinds of roles an Agent fills.
class AgentRole < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  has_many :agents_data_objects
  has_many :agents_synonyms

  def to_s
    label
  end

  def self.attribution_order
    labels = [ :Author, :Source, :Project, :Publisher ]
    labels.map {|l| cached_find(:label, l.to_s) }
  end
  
  # Find the Author
  def self.author
    cached_find(:label, 'Author')
  end
  
  # Find the Source
  def self.source
    cached_find(:label, 'Source')
  end
  
  # Find the "contributor" AgentRole.
  def self.contributor
    cached_find(:label, 'Contributor')
  end
  
  # Find the "Photographer" AgentRole.
  def self.photographer
    cached_find(:label, 'Photographer')
  end
end
