class TranslatedResourceStatus < ActiveRecord::Base
  belongs_to :resource_status
  belongs_to :language
end
