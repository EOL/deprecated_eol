class Ref < SpeciesSchemaModel

  has_many :ref_identifiers
  
  has_and_belongs_to_many :data_objects
  has_and_belongs_to_many :taxa

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: refs
#
#  id             :integer(4)      not null, primary key
#  full_reference :string(400)     not null

