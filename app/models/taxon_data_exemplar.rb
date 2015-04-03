class TaxonDataExemplar < ActiveRecord::Base

  belongs_to :taxon_concept
  belongs_to :trait

  attr_accessible :taxon_concept, :taxon_concept_id,  :trait, :trait_id, :exclude

  scope :excluded, -> { where(exclude: true) }
  scope :included, -> { where(exclude: false) }

  def self.remove(what)
    TaxonDataExemplar.delete_all(trait_id: what.id,
                                 taxon_concept_id: what.taxon_concept_id)
  end

  # TODO - Because of warnings, it's not clear to me that this ever actually works.  Check.
  def excluded?
    exclude == true
  end

  # TODO - Because of warnings, it's not clear to me that this ever actually works.  Check.
  def included?
    exclude == false
  end

end
