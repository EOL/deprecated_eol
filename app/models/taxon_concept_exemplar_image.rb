class TaxonConceptExemplarImage < SpeciesSchemaModel
  belongs_to :data_object
  has_many :taxon_concepts
  set_primary_key :taxon_concept_id

  def self.set_exemplar(taxon_concept_id, data_object_id)
    exemplar = self.find_or_create_by_taxon_concept_id(taxon_concept_id)
    exemplar.update_attribute(:data_object_id, data_object_id)
    
    top_concept_images = TopConceptImage.find_all_by_taxon_concept_id(taxon_concept_id)
    top_concept_images.each do |tci|
      tci.data_object_id == data_object_id.to_i ? tci.destroy : tci.update_attribute(:view_order, tci.view_order += 1)
    end
    TopConceptImage.create(:taxon_concept_id => taxon_concept_id, :data_object_id => data_object_id, :view_order => 1)
  end
end