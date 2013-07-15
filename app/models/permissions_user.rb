# Stupid join model because Rails 3 doesn't handle timestamps on simple join models unless they're first-class models.  Google it.
class PermissionsUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :permission
end
