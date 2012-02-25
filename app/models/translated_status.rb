class TranslatedStatus < ActiveRecord::Base
  belongs_to :status
  belongs_to :language
end
