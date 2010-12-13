class CreateRolesOnExistingCommunities < ActiveRecord::Migration
  def self.up
    Community.all.each do |community|
      community.add_default_roles
    end
    community = Community.admins
    admin_roles = {'Admin' => 20, 'Moderator' => 10}
    admin_roles.keys.each do |key|
      role = Role.find(:first, :conditions => ['title = ? and community_id = ?', key, community.id])
      role ||= Role.create(:community_id => community.id, :title => key)
      role.privileges = Privilege.find(:all, :conditions => ["level <= ? and type = 'admin'", admin_roles[key]])
    end
    community = Community.curators
    curator_roles = {'Curator' => 10, 'Associate' => 1}
    curator_roles.keys.each do |key|
      role = Role.find(:first, :conditions => ['title = ? and community_id = ?', key, community.id])
      role ||= Role.create(:community_id => community.id, :title => key)
      role.privileges = Privilege.find(:all, :conditions => ["level <= ? and type = 'curator'", curator_roles[key]])
    end
  end

  def self.down
    puts "WARNING: Nothing to do.  The #up method only created communities and I don't want to delete them."
  end
end
