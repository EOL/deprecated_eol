class Permission < ActiveRecord::Base

  uses_translations

  has_many :permissions_users
  has_many :users, through: :permissions_users

  include NamedDefaults

  set_defaults :name,
    ["Edit Permissions", "Beta Test", "See Data", "Edit CMS"]

  # NOTE - I don't know why 'self' is required here, but it's nil otherwise. :|
  def inc_user_count
    reload
    self.users_count += 1
    save
  end

  def dec_user_count
    reload
    self.users_count -= 1
    self.users_count = 0 if self.users_count < 0
    save
  end

  def <=>(other)
    self.name <=> other.name
  end
end
