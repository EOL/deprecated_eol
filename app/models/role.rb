# Every user can belong to one or more roles which grant that user access to various sections of the site.  There are more
# roles than are hard-coded here (namely various admin roles), but these are required.
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
