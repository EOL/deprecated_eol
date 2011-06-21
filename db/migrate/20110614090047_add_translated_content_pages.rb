class AddTranslatedContentPages < ActiveRecord::Migration
  def self.up
    create_table :translated_content_pages do |t|
      t.references :content_page
      t.references :language
      t.string :title
      t.text :left_content
      t.text :main_content
      t.string :url
      t.string :meta_keywords
      t.string :meta_description
      t.timestamps 
    end
  end

  def self.down
    drop_table :translated_content_pages
  end
end
