class UpdateContentPageArchives < ActiveRecord::Migration
    
  def self.up
    add_column :content_page_archives,:language_abbr, :string,:null=>false, :default=>'en'
    add_column :content_page_archives,:url, :string,:null=>true, :default=>''
    add_column :content_page_archives,:open_in_new_window, :boolean,:null=>true, :default=>false
    add_column :content_page_archives,:last_update_user_id,:integer,:null=>false, :default=>User.find_by_username('admin').id
    add_column :content_pages,:last_update_user_id,:integer,:null=>false, :default=>User.find_by_username('admin').id
  end

  def self.down
   remove_column :content_page_archives,:language_abbr
   remove_column :content_page_archives,:url
   remove_column :content_page_archives,:open_in_new_window    
   remove_column :content_page_archives,:last_update_user_id
   remove_column :content_pages,:last_update_user_id
  end

end
