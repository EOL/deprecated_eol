class DataObjectsTaxon < SpeciesSchemaModel

  set_primary_keys :data_object_id, :taxon_id

  belongs_to :data_object
  belongs_to :taxon

  has_many :data_objects

end
# == Schema Info
# Schema version: 20081002192244
#
# Table name: data_objects_taxa
#
#  data_object_id :integer(4)      not null
#  taxon_id       :integer(4)      not null
#  identifier     :string(255)     not null

# == Schema Info
# Schema version: 20081020144900
#
# Table name: data_objects_taxa
#
#  data_object_id :integer(4)      not null
#  taxon_id       :integer(4)      not null
#  identifier     :string(255)     not null

