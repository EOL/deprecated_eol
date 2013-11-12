class SpecialCollection < ActiveRecord::Base

  has_many :lists

  include EnumDefaults

  set_defaults :name,
    %w{Focus Watch}

end
