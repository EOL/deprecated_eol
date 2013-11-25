class SpecialCollection < ActiveRecord::Base

  has_many :lists

  include Enumerated
  enumerated :name, %w(Focus Watch)

end
