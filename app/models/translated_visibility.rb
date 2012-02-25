class TranslatedVisibility < ActiveRecord::Base
  belongs_to :visibility
  belongs_to :language
end
