class InfoItem < SpeciesSchemaModel
  has_and_belongs_to_many :data_objects
  belongs_to :toc_item, :foreign_key => :toc_id
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

