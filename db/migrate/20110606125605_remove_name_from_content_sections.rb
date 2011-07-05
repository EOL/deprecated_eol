class RemoveNameFromContentSections < ActiveRecord::Migration
  def self.up
    remove_column :content_sections, :name
  end

  def self.down
    add_column :content_sections, :name, :string
  end
end
