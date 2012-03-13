class TranslatedUntrustReason < ActiveRecord::Base
  belongs_to :untrust_reason
  belongs_to :language
end
