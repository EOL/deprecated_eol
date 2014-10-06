# Trying out Closure Tree...
class Concept < ActiveRecord::Base
  belongs_to :hierarchy
  belongs_to :name
  belongs_to :rank
  belongs_to :taxon_concept
  belongs_to :vetted
  belongs_to :visibility

  scope :published, -> { where(published: true) }

  acts_as_tree
end
