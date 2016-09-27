class Permission < ActiveRecord::Base

  uses_translations

  has_many :permissions_users
  has_many :users, through: :permissions_users

  include Enumerated
  enumerated :name, ['edit permissions', 'beta test', 'see data', 'edit cms', 'harvest notifications']

  KNOWN_PERMISSIONS = [ :edit_permissions, :beta_test, :see_data, :edit_cms ]

  def self.method_missing(sym, *args, &block)
    super unless KNOWN_PERMISSIONS.include?(sym)
    cached_find_translated(:name, Permission.stringify_sym(sym)) || super
  end

  def self.stringify_sym(sym)
    sym.to_s.gsub('_', ' ')
  end

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
