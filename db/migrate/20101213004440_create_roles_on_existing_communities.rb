class CreateRolesOnExistingCommunities < ActiveRecord::Migration
  def self.up
    #EOL::DB::toggle_eol_data_connections(:eol_data)
    #Community.all.each do |community|
    #  community.add_default_roles
    #end
    Community.create_special
    EOL::DB::toggle_eol_data_connections(:eol)
  end

  def self.down
    puts "WARNING: Nothing to do.  The #up method only created roles in communities and I don't want to delete them."
  end
end
