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
    labels.map {|l| AgentRole.find_by_label(l.to_s) }
  end
  
  # Find the Author
  def self.author
    $LOCAL_CACHE.agent_role_author ||= cached_find(:label, 'Author')
  end
  
  # Find the Source
  def self.source
    $LOCAL_CACHE.agent_role_source ||= cached_find(:label, 'Source')
  end
  
  # Find the "contributor" AgentRole.
  def self.contributor
    $LOCAL_CACHE.agent_role_contributor ||= cached_find(:label, 'Contributor')
  end
  
  # Find the "Photographer" AgentRole.
  def self.photographer
    $LOCAL_CACHE.agent_role_photographer ||= cached_find(:label, 'Contributor')
  end
end
