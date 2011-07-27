class UsersUserIdentity < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_identity
end