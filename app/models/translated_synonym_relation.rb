class TranslatedSynonymRelation < SpeciesSchemaModel
  belongs_to :synonym_relation
  belongs_to :language
end
