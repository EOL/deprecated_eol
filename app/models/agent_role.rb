# An enumerated list of the different kinds of roles an Agent fills.
class AgentRole < ActiveRecord::Base

  uses_translations

  has_many :agents_data_objects
  has_many :agents_synonyms

  include Enumerated
  enumerated :label, ['Author', 'Source', 'Source Database', 'Contributor', 'Photographer', 'Editor', 'provider' ]

  def to_s
    label
  end

  def self.attribution_order
    @@attribution_order ||= [ AgentRole.author, AgentRole.source, AgentRole.project, AgentRole.publisher ]
  end

end
