class TranslatedServiceType < SpeciesSchemaModel
  belongs_to :service_type
  belongs_to :language
end
