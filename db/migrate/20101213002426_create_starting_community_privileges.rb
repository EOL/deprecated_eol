class CreateStartingCommunityPrivileges < ActiveRecord::Migration

  def self.up
    KnownPrivileges.create_all
  end

  def self.down
    KnownPrivileges.symbols.each {|s| Privilege.delete_all(:sym => s) }
  end

end
