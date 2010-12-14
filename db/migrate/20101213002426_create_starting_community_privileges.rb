class CreateStartingCommunityPrivileges < ActiveRecord::Migration

  @@community_privs = {
    'Edit/Delete Community' => 20,
    'Grant level 20 Privileges' => 20,
    'Revoke level 20 Privileges' => 20,
    'Add members' => 10,
    'Remove members' => 10,
    'Grant level 10 Privileges' => 10,
    'Revoke level 10 Privileges' => 10,
    'Create Badges' => 10,
    'Revoke Badges' => 10,
    'Track User Identities' => 10,
    'Award Badges' => 5,
    'Edit Lists' => 5,
    'Endorse Lists' => 5,
    'Create Newsfeed Posts' => 5,
    'Invite Users' => 5
  }

  @@special_privs = {
    'Admin' => 20,
    'Vet' => 10,
    'Trusted Author' => 10,
    'Show/Hide Comments' => 10,
    'Rate' => 1
  }

  def self.up

    @@special_privs.keys.each do |key|
      Privilege.create(:name => key, :sym => key.gsub(/[^A-Za-z0-9]/, '_').downcase, :level => @@special_privs[key], :special => true)
    end

    @@community_privs.keys.each do |key|
      Privilege.create(:name => key,
                       :sym => key.gsub(/[^A-Za-z0-9]/, '_').downcase,
                       :level => @@community_privs[key],
                       :type => 'community')
    end

  end

  def self.down
    @@special_privs.keys.each { |k| Privilege.delete_all(:name => k) }    
    @@community_privs.keys.each { |k| Privilege.delete_all(:name => k) }    
  end

end
