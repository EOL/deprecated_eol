class CopyUserLogToContentPartners < ActiveRecord::Migration
  def self.up
    # add to content_partners the fields we need
    execute "ALTER TABLE content_partners ADD `logo_cache_url` bigint(20) unsigned default NULL"
    execute "ALTER TABLE content_partners ADD `logo_file_name` varchar(255) default NULL"
    execute "ALTER TABLE content_partners ADD `logo_content_type` varchar(255) default NULL"
    execute "ALTER TABLE content_partners ADD `logo_file_size` int(10) unsigned default '0'"
    
    # migrate the data
    ContentPartner.find(:all, :include => :user).each do |cp|
      cp.logo_cache_url = cp.user.logo_cache_url
      cp.logo_file_name = cp.user.logo_file_name
      cp.logo_content_type = cp.user.logo_content_type
      cp.logo_file_size = cp.user.logo_file_size
      cp.save
    end
  end

  def self.down
    remove_column :content_partners, :logo_cache_url
    remove_column :content_partners, :logo_file_name
    remove_column :content_partners, :logo_content_type
    remove_column :content_partners, :logo_file_size
  end
end
