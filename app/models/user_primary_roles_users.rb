class UserPrimaryRolesUsers < ActiveRecord::Base
  belongs_to :users
  belongs_to :user_primary_roles
end
