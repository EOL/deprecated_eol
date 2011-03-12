class TranslatedResourceStatus < SpeciesSchemaModel
  belongs_to :resource_status
  belongs_to :language
end
