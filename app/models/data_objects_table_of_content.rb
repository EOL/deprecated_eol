class DataObjectsTableOfContent < SpeciesSchemaModel
  belongs_to :data_object
  belongs_to :toc_item, :foreign_key => :toc_id
  set_primary_keys :data_object_id, :toc_id
  # This is only here to help specs load things to the right database.  Ignore it.
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: data_objects_table_of_contents
#
#  data_object_id :integer(4)      not null
#  toc_id         :integer(2)      not null

