class AddPageLocationToContentSections < ActiveRecord::Migration
  def self.up
    add_column :content_sections, :page_location, :string
  end

  def self.down
    remove_column :content_sections, :page_location
  end
end
