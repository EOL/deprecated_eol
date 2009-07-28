class CollectionTypesCollection < SpeciesSchemaModel
  belongs_to :collection
  belongs_to :collection_type
  set_primary_keys :collection_type_id, :collection_id
  # This is only here to help specs load things to the right database.  Ignore it.
end

