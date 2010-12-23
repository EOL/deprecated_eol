class CreateRolesOnExistingCommunities < ActiveRecord::Migration
  def self.up
    Community.all.each do |community|
      community.add_default_roles
    end
    Community.create_special
  end

  def self.down
    puts "WARNING: Nothing to do.  The #up method only created roles in communities and I don't want to delete them."
  end
end
