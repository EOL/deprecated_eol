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

  def self.create_enumerated
    enumeration_creator(autoinc: :sort_order)
  end

end
