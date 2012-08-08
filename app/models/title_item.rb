class TitleItem < ActiveRecord::Base
  has_many :item_pages
  belongs_to :publication_title
end
