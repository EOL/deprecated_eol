class TranslatedInfoItem < ActiveRecord::Base
  belongs_to :info_item
  belongs_to :language
end
