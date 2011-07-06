class RemoveContentSectionIdFromContentPages < ActiveRecord::Migration
  def self.up
    remove_column :content_pages, :content_section_id
  end

  def self.down
    add_column :content_pages, :content_section_id, :int
  end
end
