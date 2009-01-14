class Audience < SpeciesSchemaModel
  has_and_belongs_to_many :data_objects
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: audiences
#
#  id    :integer(1)      not null, primary key
#  label :string(100)     not null

