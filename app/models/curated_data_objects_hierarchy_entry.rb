class CuratedDataObjectsHierarchyEntry < SpeciesSchemaModel

  belongs_to :user
  belongs_to :data_object
  belongs_to :hierarchy_entry
  belongs_to :vetted
  belongs_to :visibility

  belongs_to :data_object_hierarchy_entry, :class_name => 'DataObjectHierarchyEntry',
    :foreign_key => [:data_object_id, :hierarchy_entry_id]

end
