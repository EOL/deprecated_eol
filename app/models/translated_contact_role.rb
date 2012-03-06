class TranslatedContactRole < ActiveRecord::Base
  belongs_to :contact_role
  belongs_to :language
end
