class InfoItem < SpeciesSchemaModel
  belongs_to :toc_item, :foreign_key => :toc_id 
  has_many   :data_objects_info_items
  has_many   :data_objects, :through => :data_objects_info_items
end

# == Schema Info
# Schema version: 20081020144900
#
# Table name: info_items
#
#  id           :integer(2)      not null, primary key
#  toc_id       :integer(2)      not null
#  label        :string(255)     not null
#  schema_value :string(255)     not null

