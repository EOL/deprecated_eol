class TaxonConceptExemplarImage < ActiveRecord::Base

  self.primary_key = :taxon_concept_id

  belongs_to :data_object
  belongs_to :taxon_concept

  def self.set_exemplar(taxon_concept, data_object_id)
    return if taxon_concept.nil?
    exemplar = self.find_or_create_by_taxon_concept_id(taxon_concept.id)
    old_dato = exemplar.data_object if exemplar.data_object
    TaxonConceptCacheClearing.new(taxon_concept).clear_for_data_objects([exemplar, old_dato])
    exemplar.update_attributes(:data_object_id => data_object_id)
    # Push down the view order of all images (note this isn't strictly required where view_order > exemplar.view_order):
    connection.execute("UPDATE top_concept_images SET view_order=view_order+1 WHERE taxon_concept_id=#{taxon_concept.id}");
    TopConceptImage.create(:taxon_concept_id => taxon_concept.id, :data_object_id => data_object_id, :view_order => 1)
  end

end
