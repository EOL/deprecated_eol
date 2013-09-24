class TaxonConceptExemplarImage < ActiveRecord::Base

  self.primary_key = :taxon_concept_id

  belongs_to :data_object
  belongs_to :taxon_concept

  attr_accessible :taxon_concept_id, :data_object_id, :taxon_concept, :data_object

  def self.set_exemplar(tcei)
    exemplar = TaxonConceptExemplarImage.find(tcei.taxon_concept.id) if TaxonConceptExemplarImage.exists?(tcei.taxon_concept.id)
    old_dato = exemplar.data_object if exemplar && exemplar.data_object
    TaxonConceptExemplarImage.delete_all(taxon_concept_id: tcei.taxon_concept.id)
    TaxonConceptCacheClearing.new(tcei.taxon_concept).clear
    tcei.save!
    TopConceptImage.push_to_top(tcei.taxon_concept, tcei.data_object)
  end

end
