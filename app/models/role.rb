# Every user can belong to one or more roles which grant that user access to various sections of the site.  There are more
# roles than are hard-coded here (namely various admin roles), but these are required.
#
# Note that we use these global variables for cached_find lookups... that's because these strings are used by controllers for
# access control, and we need to have them available before Gibberish can be used to do translations.
class Role < ActiveRecord::Base
  
  has_and_belongs_to_many :users
  validates_presence_of :title

  def self.curator
    cached_find(:title, $CURATOR_ROLE_NAME)
  end

  def self.moderator
    cached_find(:title, 'Moderator')
  end

  def self.administrator
    cached_find(:title, $ADMIN_ROLE_NAME)
  end

end
