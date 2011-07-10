class TranslatedSortStyle < ActiveRecord::Base
  belongs_to :language
  belongs_to :sort_style
end
