# Represents a system mime/type.  Used by DataObject.
class MimeType < SpeciesSchemaModel
  has_many :data_objects
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: mime_types
#
#  id    :integer(2)      not null, primary key
#  label :string(255)     not null

