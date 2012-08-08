class PublicationTitle < ActiveRecord::Base
  has_many :title_items
  # Just used for fixtures, for now.
end
