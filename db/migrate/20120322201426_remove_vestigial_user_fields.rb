class RemoveVestigialUserFields < ActiveRecord::Migration
  def self.up
    remove_column :users, :default_taxonomic_browser
    remove_column :users, :vetted
    remove_column :users, :expertise
    remove_column :users, :filter_content_by_hierarchy
    remove_column :users, :flash_enabled
    remove_column :users, :default_hierarchy_id
    remove_column :users, :secondary_hierarchy_id
    remove_column :users, :content_level
  end

  def self.down
    add_column :users, :flash_enabled, :integer, :limit => 1
    add_column :users, :filter_content_by_hierarchy, :integer, :limit => 1
    add_column :users, :vetted, :integer, :limit => 1
    add_column :users, :expertise, :string, :limit => 24
    add_column :users, :default_taxonomic_browser, :string, :limit => 24
    add_column :users, :default_hierarchy_id, :integer
    add_column :users, :secondary_hierarchy_id, :integer
    add_column :users, :content_level, :integer
  end
end
