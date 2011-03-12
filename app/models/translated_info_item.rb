class TranslatedInfoItem < SpeciesSchemaModel
  belongs_to :info_item
  belongs_to :language
end
