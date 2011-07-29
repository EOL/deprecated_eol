class TaxonConceptExemplarImage < SpeciesSchemaModel
  belongs_to :data_object
  has_many :taxon_concepts
  set_primary_key :taxon_concept_id

  def self.set_exemplar(taxon_concept_id, data_object_id)
    exemplar = self.find_or_create_by_taxon_concept_id(taxon_concept_id)
    exemplar.update_attribute(:data_object_id, data_object_id)

    tci_exists = TopConceptImage.find_by_taxon_concept_id_and_data_object_id(taxon_concept_id, data_object_id)
    tci_exists.destroy unless tci_exists.nil?
    connection.execute("UPDATE top_concept_images SET view_order=view_order+1 WHERE taxon_concept_id=#{taxon_concept_id}");
    TopConceptImage.create(:taxon_concept_id => taxon_concept_id, :data_object_id => data_object_id, :view_order => 1)
  end
end