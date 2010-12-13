# Roles serve two purposes.
#
# Firstly, they are titles.  They are associated with a community and *show* some kind of expected level of access for a user
# within that community.  However, ROLES GRANT NO POWER WITHIN THEMSELVES.
#
# Secondly, they store a list of privileges (which actually grant power, q.v.).  You can #assign_privileges_to a user at any
# given time to ensure that the user has all of the privileges associated with a role.  However, if the list of allowed
# privileges associated with that role changes at a later date, the powers of the users who had that role DO NOT NECESSARILY
# CHANGE.  (This will be an option, but is not a reqirement).  So you *can* have users with privileges outside of the scope
# of a role, at any given time.
#
# Note that there are no "universal" Roles. Every role is attached to a community.  And, in fact, there are a few "default"
# roles that are assigned to a community when it's created... but they can be changed later.  So there may be what appear
# like a lot of duplicates in the roles table.  But each community has full control of that role, so they are in fact
# separate entities.  See Role#add_defaults_to_community.
class Role < ActiveRecord::Base
  
  belongs_to :community
  has_and_belongs_to_many :users
  has_and_belongs_to_many :privileges

  validates_presence_of :title

  def self.curator
    logger.error "Called deprecated Role#curator.  This will be removed eventually.  Stop it."
    cached_find(:title, $CURATOR_ROLE_NAME)
  end
  def self.moderator
    logger.error "Called deprecated Role#moderator.  This will be removed eventually.  Stop it."
    cached_find(:title, 'Moderator')
  end
  def self.administrator
    logger.error "Called deprecated Role#administrator.  This will be removed eventually.  Stop it."
    cached_find(:title, $ADMIN_ROLE_NAME)
  end

  # TODO - with master?
  # TODO - test
  def self.add_defaults_to_community(community)
    default_roles = {'Owner' => 20, 'Member Services Manager' => 10, 'Content Manager' => 1}
    new_roles = []
    default_roles.keys.each do |key|
      unless self.exists?(['title = ? and community_id = ?', key, community.id])
        new_roles << self.create(:community_id => community.id, :title => key)
        new_roles.last.privileges = Privilege.find(:all, :conditions => ["type = 'community' and level <= ?", default_roles[key]])
        new_roles.last.save!
      end
    end
    community.roles += new_roles
    new_roles
  end

  def assign_privileges_to(user)
    member = user.member_of(community)
    raise "User is not a member of the community for this role." unless member
    member.assign_privileges privileges
  end

end
