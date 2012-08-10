class TaxonConceptExemplarArticle < ActiveRecord::Base
  belongs_to :data_object
  belongs_to :taxon_concept
  self.primary_key = :taxon_concept_id

  def self.set_exemplar(taxon_concept_id, data_object_id)
    exemplar = self.find_or_create_by_taxon_concept_id(taxon_concept_id)
    exemplar.update_attributes(:data_object_id => data_object_id)
    Rails.cache.delete(TaxonConcept.cached_name_for("best_article_#{taxon_concept_id}"))
  end
end
