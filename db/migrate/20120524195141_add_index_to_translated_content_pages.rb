class AddIndexToTranslatedContentPages < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX content_page_id ON translated_content_pages(content_page_id)"
  end

  def self.down
    remove_index :translated_content_pages, :content_page_id
  end
end
