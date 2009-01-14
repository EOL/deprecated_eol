class PublicationTitle < SpeciesSchemaModel
  has_many :title_items
  # Just used for fixtures, for now.
end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: publication_titles
#
#  id           :integer(4)      not null, primary key
#  marc_bib_id  :string(40)      not null
#  abbreviation :string(150)     not null
#  author       :string(150)     not null
#  call_number  :string(40)      not null
#  details      :string(300)     not null
#  end_year     :string(10)      not null
#  language     :string(10)      not null
#  marc_leader  :string(40)      not null
#  short_title  :string(300)     not null
#  start_year   :string(10)      not null
#  title        :string(300)     not null
#  url          :string(255)     not null

