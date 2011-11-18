class TranslatedViewStyle < ActiveRecord::Base
  belongs_to :language
  belongs_to :view_style
end
