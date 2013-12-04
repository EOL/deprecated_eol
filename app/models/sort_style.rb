class SortStyle < ActiveRecord::Base

  CACHE_ALL_ROWS = true
  uses_translations
  has_many :collections

  include Enumerated
  enumerated :name, 
        [{newest: 'Recently Added'},
         'Oldest',
         'Alphabetical',
         'Reverse Alphabetical',
         'Richness',
         'Rating',
         'Sort Field',
         'Reverse Sort Field']

end
