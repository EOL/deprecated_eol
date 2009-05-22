class RefIdentifierType < SpeciesSchemaModel

  has_many :ref_identifiers

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: ref_identifier_types
#
#  id    :integer(2)      not null, primary key
#  label :string(50)      not null

