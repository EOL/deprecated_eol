# TODO - ADD COMMENTS
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

