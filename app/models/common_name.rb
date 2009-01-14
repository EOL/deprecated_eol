class CommonName < SpeciesSchemaModel

  belongs_to :language

  has_and_belongs_to_many :taxa

end# == Schema Info
# Schema version: 20080922224121
#
# Table name: common_names
#
#  id          :integer(4)      not null, primary key
#  language_id :integer(2)      not null
#  common_name :string(255)     not null

# == Schema Info
# Schema version: 20081020144900
#
# Table name: common_names
#
#  id          :integer(4)      not null, primary key
#  language_id :integer(2)      not null
#  common_name :string(255)     not null

