class SortStyle < ActiveRecord::Base
  CACHE_ALL_ROWS = true
  uses_translations
  has_many :collections

  include EnumDefaults

  set_defaults :name,
    [{name: 'Recently Added', method_name: :newest},
     {name: 'Oldest'},
     {name: 'Alphabetical'},
     {name: 'Reverse Alphabetical'},
     {name: 'Richness'},
     {name: 'Rating'},
     {name: 'Sort Field'},
     {name: 'Reverse Sort Field'}]

end
