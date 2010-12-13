class AssignMembersToRoles < ActiveRecord::Migration
  def self.up
    # NOTE - Theoretically, there could be new communities with members that have no roles/privs, but we don't care about
    # that, since it's more likely this migration will be run on a pre-community version of the site.
    curator_role = Role.find(:first, :conditions => "title = '#{$CURATOR_ROLE_NAME}' AND community_id IS NULL")
    if curator_role
      curator_role.users.each do |user|
        user.join_community(Community.curators)
        Role.find(:first, :conditions => ["title = 'Curator' AND community_id = ?", Community.curators.id]).assign_privileges_to(user) 
      end
    end
    # It so happens that all our moderators are admins, so we'll use the admin version of moderation:
    mod_role = Role.find(:first, :conditions => "title = 'Moderator' AND community_id IS NULL")
    if mod_role
      mod_role.users.each do |user|
        user.join_community(Community.admins)
        Role.find(:first, :conditions => ["title = 'Moderator' AND community_id = ?", Community.admins.id]).assign_privileges_to(user)
      end
    end
    completed_user_ids = []
    admin_role = Role.find(:first, :conditions => ['title = "admin" and community_id = ?', Community.admins.id])
    Role.find(:all, :conditions => 'title LIKE "admin%" AND community_id IS NULL').each do |role|
      role.users.each do |user|
        next if completed_user_ids.include? user.id
        user.join_community(Community.admins)
        admin_role.assign_privileges_to(user)
        completed_user_ids << user.id
      end
    end
    Role.destroy_all('community_id IS NULL') # We don't want these any more.
  end

  def self.down
    puts "WARNING: Nothing to do.  The #up method only assigned privileges and I don't want to remove them."
  end
end
