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

  @@curator_privs = {
    'Vet' => 10,
    'Trusted Author' => 10,
    'Show/Hide Comments' => 10,
    'Rate' => 1
  }

  @@admin_privs = {
    'Admin' => 20,
    'Show/Hide Comments' => 10
  }

  def self.up

    @@admin_privs.keys.each do |key|
      Privilege.create(:name => key,
                       :sym => key.gsub(/[^A-Za-z0-9]/, '_').downcase,
                       :level => @@admin_privs[key],
                       :type => 'admin')
    end

    @@community_privs.keys.each do |key|
      Privilege.create(:name => key,
                       :sym => key.gsub(/[^A-Za-z0-9]/, '_').downcase,
                       :level => @@community_privs[key],
                       :type => 'community')
    end

    @@curator_privs.keys.each do |key|
      Privilege.create(:name => key,
                       :sym => key.gsub(/[^A-Za-z0-9]/, '_').downcase,
                       :level => @@curator_privs[key],
                       :type => 'curator')
    end

  end

  def self.down
    @@admin_privs.keys.each { |k| Privilege.find_by_name(key).destroy! }    
    @@curator_privs.keys.each { |k| Privilege.find_by_name(key).destroy! }    
    @@community_privs.keys.each { |k| Privilege.find_by_name(key).destroy! }    
  end

end
