class RemoveOpenInNewWindowFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :open_in_new_window
    remove_column :content_page_archives, :open_in_new_window
  end

  def self.down
    add_column :content_pages, :open_in_new_window, :tinyint
    add_column :content_page_archives, :open_in_new_window, :tinyint
  end
end
