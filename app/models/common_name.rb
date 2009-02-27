# Used only to cache common names supplied by content partners through their resources.
#
# Don't be fooled... to actually find a common name, you should look at the Name model.
class CommonName < SpeciesSchemaModel

  belongs_to :language

  has_and_belongs_to_many :taxa

end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: common_names
#
#  id          :integer(4)      not null, primary key
#  language_id :integer(2)      not null
#  common_name :string(255)     not null

