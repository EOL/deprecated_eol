class TranslatedUserIdentity < ActiveRecord::Base
  belongs_to :user_identity
  belongs_to :language
end
