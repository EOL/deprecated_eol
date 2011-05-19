class DataObjectsHierarchyEntry < SpeciesSchemaModel

  set_primary_keys :data_object_id, :hierarchy_entry_id

  belongs_to :data_object
  belongs_to :hierarchy_entry

end
