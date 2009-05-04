class RefIdentifier < SpeciesSchemaModel

  set_primary_key :ref_id, :ref_identifier_type_id

  belongs_to :ref
  belongs_to :ref_identifier_type

  has_and_belongs_to_many :taxa

end

# == Schema Info
# Schema version: 20080922224121
#
# Table name: ref_identifiers
#
#  ref_id                 :integer(4)      not null
#  ref_identifier_type_id :integer(2)      not null
#  identifier             :string(255)     not null

# == Schema Info
# Schema version: 20081020144900
#
# Table name: ref_identifiers
#
#  ref_id                 :integer(4)      not null
#  ref_identifier_type_id :integer(2)      not null
#  identifier             :string(255)     not null

