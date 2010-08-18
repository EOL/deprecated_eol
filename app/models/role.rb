# TODO document - i'm not sure where Role is used
class Role < ActiveRecord::Base
  
  has_and_belongs_to_many :users
  validates_presence_of :title

  def self.curator
    cached_find(:title, 'Curator')
  end

  def self.moderator
    cached_find(:title, 'Moderator')
  end

  def self.administrator
    cached_find(:title, 'Administrator')
  end

end
# == Schema Info
# Schema version: 20081020144900
#
# Table name: roles
#
#  id         :integer(4)      not null, primary key
#  title      :string(255)
#  created_at :datetime
#  updated_at :datetime

