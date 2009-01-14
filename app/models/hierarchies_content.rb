# TODO - ADD COMMENTS
class HierarchiesContent < SpeciesSchemaModel
  set_table_name 'hierarchies_content'
  belongs_to :hierarchy_entry
  set_primary_key :hierarchy_entry_id
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: hierarchies_content
#
#  hierarchy_entry_id :integer(4)      not null, primary key
#  hierarchy_entry_id :integer(4)      not null, primary key
#  image_object_id    :integer(4)      not null
#  child_image        :integer(1)      not null
#  content_level      :integer(1)      not null
#  flash              :integer(1)      not null
#  gbif_image         :integer(1)      not null
#  image              :integer(1)      not null
#  internal_image     :integer(1)      not null
#  text               :integer(1)      not null
#  youtube            :integer(1)      not null

