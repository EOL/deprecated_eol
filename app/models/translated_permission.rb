class TranslatedPermission < ActiveRecord::Base
  belongs_to :permission
  belongs_to :language
end
