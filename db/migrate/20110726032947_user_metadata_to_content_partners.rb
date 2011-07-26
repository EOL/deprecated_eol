class UserMetadataToContentPartners < ActiveRecord::Migration
  def self.up
    # add to content_partners the fields we need
    execute "ALTER TABLE content_partners ADD `full_name` text AFTER `user_id`"
    execute "ALTER TABLE content_partners ADD `display_name` varchar(255) AFTER `full_name`"
    execute "ALTER TABLE content_partners ADD `acronym` varchar(20) AFTER `display_name`"
    execute "ALTER TABLE content_partners ADD `homepage` varchar(255) AFTER `acronym`"
    
    # migrate the data
    ContentPartner.find(:all, :include => :user).each do |cp|
      cp.full_name = cp.user.given_name
      cp.display_name = cp.user.display_name
      cp.acronym = cp.user.acronym
      cp.homepage = cp.user.homepage
      cp.save
    end
    
    # now remove the fields from users
    remove_column :users, :display_name
    remove_column :users, :acronym
    remove_column :users, :homepage
  end

  def self.down
    execute "ALTER TABLE users ADD `display_name` varchar(255) AFTER `family_name`"
    execute "ALTER TABLE users ADD `acronym` varchar(20) AFTER `display_name`"
    execute "ALTER TABLE users ADD `homepage` varchar(255) AFTER `acronym`"
    
    remove_column :content_partners, :full_name
    remove_column :content_partners, :display_name
    remove_column :content_partners, :acronym
    remove_column :content_partners, :homepage
  end
end
