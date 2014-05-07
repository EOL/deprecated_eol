# TODO - remove this. I don't think we use it anymore; I think we use UserIdentity.
class UserPrimaryRolesUsers < ActiveRecord::Base
  belongs_to :users
  belongs_to :user_primary_roles
end
