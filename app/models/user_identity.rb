class UserIdentity < ActiveRecord::Base

  uses_translations
  
  has_many :users_user_identities
  has_many :users, :through => :users_user_identities

  include NamedDefaults

  set_defaults :label,
    [ "an enthusiast",
      "a student",
      "an educator",
      "a citizen scientist",
      "a professional scientist" ],
    autoinc_field: :sort_order
    
end
