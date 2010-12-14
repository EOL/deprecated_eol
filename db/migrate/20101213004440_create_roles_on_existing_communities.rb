class CreateRolesOnExistingCommunities < ActiveRecord::Migration
  def self.up
    special = Community.special
    special ||= Community.create(:name => 'EOL Curators and Admins', :description => 'This is a special community for the curtors and admins of EOL.', :show_special_privileges => 0)
    Community.all.each do |community|
      community.add_default_roles
    end
    special_roles = {'Admin' => 20, 'Curator' => 10, 'Associate' => 1}
    special_roles.keys.each do |key|
      role = Role.find(:first, :conditions => ['title = ? and community_id = ?', key, special.id])
      role ||= Role.create(:community_id => special.id, :title => key)
      role.privileges = Privilege.find(:all, :conditions => ["level <= ? and special = ?", special_roles[key], true])
    end
  end

  def self.down
    puts "WARNING: Nothing to do.  The #up method only created communities and I don't want to delete them."
  end
end
