class RefsTaxon < SpeciesSchemaModel
  
  belongs_to :taxon
  belongs_to :ref
  
end