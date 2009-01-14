class TaxonConceptContent < SpeciesSchemaModel
  set_table_name 'taxon_concept_content'
  belongs_to :taxon_concept
  set_primary_key :taxon_concept_id
end