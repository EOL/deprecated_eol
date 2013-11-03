class SpecialCollection < ActiveRecord::Base

  has_many :lists

  include NamedDefaults

  set_defaults :name,
    %w{Focus Watch}

end
