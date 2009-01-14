class Role < ActiveRecord::Base
  
  has_and_belongs_to_many :users
  validates_presence_of :title
    
  def self.curator
    @cur ||= Role.find_by_title('Curator')
  end

  def self.moderator
    @mod ||= Role.find_by_title('Moderator')
  end

  def self.administrator
    @admin ||= Role.find_by_title('Administrator')
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

