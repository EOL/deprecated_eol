class TaxonConceptExemplarImage < SpeciesSchemaModel
  belongs_to :data_object
  has_many :taxon_concepts
  set_primary_key :taxon_concept_id

  def self.set_exemplar(taxon_concept_id, data_object_id)
    exemplar = self.find_or_create_by_taxon_concept_id(taxon_concept_id)
    exemplar.update_attribute(:data_object_id, data_object_id)
    # Add entry in top_concept_images table if doesn't exist already
    TopConceptImage.find_or_create_by_taxon_concept_id_and_data_object_id_and_view_order(taxon_concept_id, data_object_id, 1)
  end
end