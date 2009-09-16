class DataObjectsInfoItem < SpeciesSchemaModel
  belongs_to :data_object
  belongs_to :info_item
  set_primary_keys :data_object_id, :info_item_id
  # This is only here to help specs load things to the right database.  Ignore it.
end
  # == Schema Info
  #
  # Table name: data_objects_info_items
  #
  #  data_object_id :integer(10)      not null
  #  info_item_id   :integer(5)      not null
