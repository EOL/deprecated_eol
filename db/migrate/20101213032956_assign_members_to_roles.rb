class AssignMembersToRoles < ActiveRecord::Migration

  @@completed_user_ids = []

  def self.join_special_community(scope, old_title, new_title)
    # Yes, using 'like' universally is a little silly.  But it works and avoids more code we don't need in a migration.
    roles = Role.find(scope, :conditions => "title LIKE '#{old_title}' AND community_id IS NULL")
    roles = [roles] unless roles.is_a? Array
    roles.each do |role|
      role.users.each do |user|
        next if @@completed_user_ids.include? user.id
        begin
          user.join_community(Community.special) 
        rescue ActiveRecord::RecordInvalid => e
          puts "** Warning: user #{user.username}(#{user.id}) is already in '#{Community.special.name}' Community."
        end
        new_role = Role.find(:first, :conditions => ["title = '#{new_title}' AND community_id = ?", Community.special.id])
        raise "Could not find a '#{new_title}' role in community #{Community.special.id}." unless new_role
        new_role.assign_privileges_to(user) 
        @@completed_user_ids << user.id
      end
    end
  end

  def self.up
    # NOTE - Theoretically, there could be new communities with members that have no roles/privs, but we don't care about
    # that, since it's more likely this migration will be run on a pre-community version of the site.
    self.join_special_community(:first, $CURATOR_ROLE_NAME, 'Curator')
    self.join_special_community(:first, 'Moderator', 'Moderator')
    self.join_special_community(:all, 'admin%', 'Admin')
    Role.destroy_all('community_id IS NULL') # We don't want these any more.
  end

  def self.down
    puts "WARNING: Nothing to do.  The #up method only assigned privileges and I don't want to remove them."
  end
end
