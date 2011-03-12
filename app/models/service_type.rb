class ServiceType < SpeciesSchemaModel
  CACHE_ALL_ROWS = true
  has_many :resources
end