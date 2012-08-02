class TaxonConceptExemplarImage < ActiveRecord::Base
  belongs_to :data_object
  belongs_to :taxon_concept
  set_primary_key :taxon_concept_id

  def self.set_exemplar(taxon_concept, data_object_id)
    return if taxon_concept.nil?
    exemplar = self.find_or_create_by_taxon_concept_id(taxon_concept.id)
    exemplar.update_attributes(:data_object_id => data_object_id)
    TopConceptImage.delete_all("taxon_concept_id = #{taxon_concept.id} AND data_object_id = #{data_object_id}")
    connection.execute("UPDATE top_concept_images SET view_order=view_order+1 WHERE taxon_concept_id=#{taxon_concept.id}");
    Rails.cache.delete(TaxonConcept.cached_name_for("best_image_#{taxon_concept.id}"))
    TopConceptImage.create(:taxon_concept_id => taxon_concept.id, :data_object_id => data_object_id, :view_order => 1)
  end
end
