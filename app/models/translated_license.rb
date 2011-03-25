class TranslatedLicense < SpeciesSchemaModel
  belongs_to :license
  belongs_to :language
end
