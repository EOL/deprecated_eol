class AddTranslatedContentPageArchives < ActiveRecord::Migration
  def self.up
    create_table :translated_content_page_archives do |t|
      t.references :translated_content_page
      t.references :content_page
      t.references :language
      t.string :title
      t.text :left_content
      t.text :main_content
      t.string :url
      t.string :meta_keywords
      t.string :meta_description
      t.date :original_creation_date
      t.date :create_at
      t.date :updated_at 
    end
  end

  def self.down
    drop_table :translated_content_page_archives
  end
end
