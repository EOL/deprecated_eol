class AddPageNameToNewsItems < ActiveRecord::Migration
  def self.up
    add_column :news_items, :page_name, :string, :after => :id
    rename_column :news_items, :user_id, :last_update_user_id
  end

  def self.down
    rename_column :news_items, :last_update_user_id, :user_id
    remove_column :news_items, :page_name
  end
end