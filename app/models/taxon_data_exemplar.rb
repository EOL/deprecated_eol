class TaxonDataExemplar < ActiveRecord::Base

  belongs_to :taxon_concept
  belongs_to :parent, :polymorphic => true

  attr_accessible :taxon_concept, :taxon_concept_id, :parent, :parent_type, :parent_id, :exclude

  scope :excluded, -> { where(exclude: true) }
  scope :included, -> { where(exclude: false) }

  def self.remove(what)
    TaxonDataExemplar.delete_all(parent_id: what.id,
                                 parent_type: what.class.name,
                                 taxon_concept_id: what.taxon_concept_id)
  end

end
