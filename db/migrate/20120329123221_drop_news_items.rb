class DropNewsItems < ActiveRecord::Migration
  def self.up
    rename_table :news_items, :old_news_items
    rename_table :translated_news_items, :old_translated_news_items
  end

  def self.down
    rename_table :old_news_items, :news_items
    rename_table :old_translated_news_items, :translated_news_items
  end
end
