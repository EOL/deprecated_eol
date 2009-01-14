class ItemPage < SpeciesSchemaModel
  has_many :page_names
  belongs_to :title_item
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: item_pages
#
#  id            :integer(4)      not null, primary key
#  title_item_id :integer(4)      not null
#  issue         :string(20)      not null
#  number        :string(20)      not null
#  page_type     :string(20)      not null
#  prefix        :string(20)      not null
#  url           :string(255)     not null
#  volume        :string(20)      not null
#  year          :string(20)      not null

