class TitleItem < SpeciesSchemaModel
  has_many :item_pages
  belongs_to :publication_title
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: title_items
#
#  id                   :integer(4)      not null, primary key
#  marc_item_id         :string(50)      not null
#  publication_title_id :integer(4)      not null
#  bar_code             :string(50)      not null
#  call_number          :string(100)     not null
#  url                  :string(255)     not null
#  volume_info          :string(100)     not null

