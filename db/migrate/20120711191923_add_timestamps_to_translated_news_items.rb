class AddTimestampsToTranslatedNewsItems < ActiveRecord::Migration
  def self.up
    change_table :translated_news_items do |t|
      t.timestamps
    end
  end

  def self.down
    remove_column :translated_news_items, :updated_at
    remove_column :translated_news_items, :created_at
  end
end
