class AlterTranslatedNewsItems < ActiveRecord::Migration
  def self.up
    change_table :translated_news_items do |t|
      t.change :body, :text
      t.remove :phonetic_body
      t.remove :phonetic_title
      t.timestamps
    end
  end

  def self.down
    change_table :translated_news_items do |t|
      t.change :body, :string, :limit => 1500
      t.string :phonetic_body, :limit => 1500
      t.string :phonetic_title
      t.remove :updated_at
      t.remove :created_at
    end
  end
end
