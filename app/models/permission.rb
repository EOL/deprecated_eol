class Permission < ActiveRecord::Base

  uses_translations

  has_and_belongs_to_many :users

  KNOWN_PERMISSIONS = [:edit_permissions, :beta_test]

  def self.create_defaults
    KNOWN_PERMISSIONS.each do |sym|
      name = Permission.stringify_sym(sym)
      perm = cached_find_translated(:name, name)
      unless perm
        perm = Permission.create
        TranslatedPermission.create(:name => name, :language => Language.default,
                                    :permission => perm)
      end
    end
  end

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

end
