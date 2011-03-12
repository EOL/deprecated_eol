class TranslatedMimeType < SpeciesSchemaModel
  belongs_to :mime_type
  belongs_to :language
end
