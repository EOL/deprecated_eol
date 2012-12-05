class TranslatedSortStyle < ActiveRecord::Base
  belongs_to :language
  belongs_to :sort_style
  
  attr_accessible :sort_style, :name, :language, :sort_style_id, :language_id
end
