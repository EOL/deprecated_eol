# Represents different ways of displaying data, based on the type of user (audience).  For example, this will allow us to show
# data objects that are written for a younger audience when it's appropriate.
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

