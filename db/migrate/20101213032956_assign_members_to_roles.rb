class RolesUser < ActiveRecord::Base # We don't want this model ANYWHERE else, it's only for this migration.
  belongs_to :role
  belongs_to :user
end

class AssignMembersToRoles < ActiveRecord::Migration

  @@completed_user_ids = []

  def self.join_special_community(scope, old_title, new_title)
    # Yes, using 'like' universally is a little silly.  But it works and avoids more code we don't need in a migration.
    roles = Role.find(scope, :conditions => "title LIKE '#{old_title}' AND community_id IS NULL")
    roles = [roles] unless roles.is_a? Array
    roles.compact!
    roles.each do |role|
      users = RolesUser.find_all_by_role_id(role.id).map {|ru| ru.user }
      users.each do |user|
        next if user.nil?
        next if @@completed_user_ids.include? user.id
        member = nil
        begin
          member = user.join_community(Community.special) 
        rescue ActiveRecord::RecordInvalid => e
          puts "** Warning: user #{user.username}(#{user.id}) is already in '#{Community.special.name}' Community."
        end
        if member
          new_role = Role.find(:first, :conditions => ["title = '#{new_title}' AND community_id = ?", Community.special.id])
          raise "Could not find a '#{new_title}' role in community #{Community.special.id}." unless new_role
          member.add_role(new_role)
          @@completed_user_ids << user.id
        else
          puts "** WARNING: couldn't create a member for #{user.username}(#{user.id}) in community #{Community.special.name}."
        end
      end
    end
  end

  def self.up
    # NOTE - Theoretically, there could be new communities with members that have no roles/privs, but we don't care about
    # that, since it's more likely this migration will be run on a pre-community version of the site.
    self.join_special_community(:first, $CURATOR_ROLE_NAME, 'Curator')
    self.join_special_community(:all, 'admin%', 'Administrator')
    Role.destroy_all('community_id IS NULL') # We don't want these any more.
    drop_table :roles_users
  end

  def self.down
    puts "** WARNING: This added a user id to the roles table, but didn't populate it.  Good luck."
    add_column :roles, :user_id, :integer
  end

end
