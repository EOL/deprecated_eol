class TranslatedContactRole < SpeciesSchemaModel
  belongs_to :contact_role
  belongs_to :language
end
