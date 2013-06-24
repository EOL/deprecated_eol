class TaxonDataExemplar < ActiveRecord::Base

  belongs_to :taxon_concept
  belongs_to :parent, :polymorphic => true

  attr_accessible :taxon_concept, :taxon_concept_id, :parent, :parent_type, :parent_id

  def self.rows_for_taxon_page(taxon_page)
    # TODO - this is, of course, dumb: we're loading ALL the data and filtering it.  Stupid.  Replace.
    data = taxon_page.is_a?(TaxonData) ? taxon_page : taxon_page.data # Just saves re-calculation...  [shrug]
    exemplars = TaxonDataExemplar.where(taxon_concept_id: taxon_page.taxon_concept.id).map(&:parent)
    data.get_all_rows.select { |row| exemplars.include?(row[:parent]) }
  end

  def self.remove(what)
    TaxonDataExemplar.delete_all(parent_id: what.id,
                                 parent_type: what.class.name,
                                 taxon_concept_id: what.taxon_concept_id)
  end

end
