class AddOpenInNewWindowToContentPage < ActiveRecord::Migration
  def self.up
    add_column :content_pages, :open_in_new_window, :tinyint
  end

  def self.down
    remove_column :content_pages, :open_in_new_window
  end
end
