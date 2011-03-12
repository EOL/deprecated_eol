class TranslatedStatus < SpeciesSchemaModel
  belongs_to :status
  belongs_to :language
end
