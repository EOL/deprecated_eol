class HierarchiesResource < SpeciesSchemaModel
  belongs_to :hierarchy
  belongs_to :resource
  set_primary_key :resource_id
end