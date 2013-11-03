# An enumerated list of the different kinds of roles an Agent fills.
class AgentRole < ActiveRecord::Base

  uses_translations

  has_many :agents_data_objects
  has_many :agents_synonyms

  include NamedDefaults

  set_defaults :label,
    ['Author', 'Source', 'Source Database', 'Contributor', 'Photographer', 'Editor', 'provider']

  def to_s
    label
  end

  def self.attribution_order
    labels = [ :Author, :Source, :Project, :Publisher ]
    labels.map {|l| cached_find_translated(:label, l.to_s) }
  end

end
