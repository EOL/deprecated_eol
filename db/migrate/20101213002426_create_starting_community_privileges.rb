class CreateStartingCommunityPrivileges < ActiveRecord::Migration

  def self.up
    Privilege.create_all
  end

  def self.down
    # Nothing to do.  Deleting all of the privs is NOT desirable; an error is not appropriate.
  end

end
