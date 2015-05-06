# The translation for KnownUri (q.v.).  Note that I'm not enforcing the name to be unique. We could, in theory, have
# multiple URIs that all "mean" the same thing. In reality, all of them but the one we prefer should be hidden... but
# hey.
class TranslatedKnownUri < ActiveRecord::Base

  belongs_to :known_uri
  belongs_to :language

  attr_accessible :name, :language, :language_id, :known_uri, :known_uri_id, :definition,
    :comment, :attribution

  validates_presence_of :name
  before_save :remove_whitespaces
  
  def remove_whitespaces
    self.name = self.name.strip if self.name
  end

end
