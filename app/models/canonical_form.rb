# A canonical form of a scientific name is the name parts without authorship,
# rank information, or anything except the latinized name parts. These are for
# the most part algorithmically generated. 
#
# Every Name should have a CanonicalForm.
class CanonicalForm < SpeciesSchemaModel
  has_many :names
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: canonical_forms
#
#  id     :integer(4)      not null, primary key
#  string :string(300)     not null

