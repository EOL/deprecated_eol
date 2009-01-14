class SynonymRelation < SpeciesSchemaModel
  has_many :synonyms
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: synonym_relations
#
#  id    :integer(2)      not null, primary key
#  label :string(255)     not null

