# a denormalized table containing all the objects a concept
# should show in its RSS feed
class DataObjectsTaxonConcept < SpeciesSchemaModel
  set_primary_keys :taxon_concept_id, :data_object_id
  belongs_to :taxon_concept
  belongs_to :data_object
  belongs_to :data_type
end
