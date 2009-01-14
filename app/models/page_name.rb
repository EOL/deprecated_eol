class PageName < SpeciesSchemaModel
  belongs_to :item_page
  belongs_to :name
  set_primary_keys :name_id, :item_page_id
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: page_names
#
#  item_page_id :integer(4)      not null
#  name_id      :integer(4)      not null

