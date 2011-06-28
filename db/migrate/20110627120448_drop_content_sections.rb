class DropContentSections < ActiveRecord::Migration
  def self.up
    drop_table :content_sections
    drop_table :translated_content_sections
  end

  def self.down
  end
end
