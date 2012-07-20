# An enumerated list of the different kinds of roles an Agent fills.
class AgentRole < ActiveRecord::Base
  uses_translations

  has_many :agents_data_objects
  has_many :agents_synonyms

  def to_s
    label
  end

  def self.attribution_order
    labels = [ :Author, :Source, :Project, :Publisher ]
    labels.map {|l| cached_find_translated(:label, l.to_s, 'en') }
  end

  # Find the Author
  def self.author
    cached_find_translated(:label, 'Author', 'en')
  end

  # Find the Source
  def self.source
    cached_find_translated(:label, 'Source', 'en')
  end

  def self.source_database
    cached_find_translated(:label, 'Source Database', 'en')
  end

  # Find the "contributor" AgentRole.
  def self.contributor
    cached_find_translated(:label, 'Contributor', 'en')
  end

  # Find the "Photographer" AgentRole.
  def self.photographer
    cached_find_translated(:label, 'Photographer', 'en')
  end

  # Find the Editor
  def self.editor
    cached_find_translated(:label, 'Editor', 'en')
  end

  # Find the Provider
  def self.provider
    cached_find_translated(:label, 'provider', 'en')
  end
end
