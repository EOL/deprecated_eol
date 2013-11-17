class UserIdentity < ActiveRecord::Base

  uses_translations

  has_many :users_user_identities
  has_many :users, :through => :users_user_identities

  include Enumerated
  enumerated :label, [
    "an enthusiast",
    "a student",
    "an educator",
    "a citizen scientist",
    "a professional scientist"
  ]

  def self.create_defaults
    default_identites = [
      "an enthusiast",
      "a student",
      "an educator",
      "a citizen scientist",
      "a professional scientist" ]

    sort_order = 1
    default_identites.each do |label|
      if !self.cached_find_translated(:label, label)
        ui = UserIdentity.create(:sort_order => sort_order)
        TranslatedUserIdentity.create(:label => label, :language => Language.english_for_migrations, :user_identity => ui)
      end
      sort_order += 1
    end

  end
end
