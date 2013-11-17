class SpecialCollection < ActiveRecord::Base

  has_many :lists

  include Enumerated
  enumerated :name, %w(Focus Watch)

  def self.create_defaults
    self.create(:name => 'Focus')
    self.create(:name => 'Watch')
  end

end
