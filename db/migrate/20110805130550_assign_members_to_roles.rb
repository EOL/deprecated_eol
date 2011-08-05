class Role < ActiveRecord::Base # We don't want this model ANYWHERE else, it's only for this migration.
end
class RolesUser < ActiveRecord::Base # We don't want this model ANYWHERE else, it's only for this migration.
  belongs_to :role
  belongs_to :user
end

class AssignMembersToRoles < ActiveRecord::Migration

  def self.move_users(old_title, &block)
    roles = Role.find(:all, :conditions => "title LIKE '#{old_title}' AND community_id IS NULL")
    @@completed_user_ids = []
    roles.compact.each do |role|
      users = RolesUser.find_all_by_role_id(role.id).map {|ru| ru.user }
      users.each do |user|
        next if user.nil?
        next if @@completed_user_ids.include? user.id
        yield(user)
        @@completed_user_ids << user.id
      end
    end
  end

  def self.up
    self.move_users('%curator%') do
      user.grant_curator
    end
    self.move_users('admin%') do |user|
      user.grant_admin
    end
    Role.destroy_all('community_id IS NULL') # We don't want these any more.
    drop_table :roles_users
  end

  def self.down
    puts "** WARNING: This added a user id to the roles table, but didn't populate it.  Good luck."
    add_column :roles, :user_id, :integer
  end

end
