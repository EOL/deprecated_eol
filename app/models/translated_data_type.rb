class TranslatedDataType < SpeciesSchemaModel
  belongs_to :data_type
  belongs_to :language
end
