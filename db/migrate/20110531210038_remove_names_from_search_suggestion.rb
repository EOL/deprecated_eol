class RemoveNamesFromSearchSuggestion < ActiveRecord::Migration
  def self.up
    remove_column :search_suggestions, :common_name
    remove_column :search_suggestions, :scientific_name
    remove_column :search_suggestions, :image_url
  end

  def self.down
    add_column :search_suggestions, :common_name, :string, :limit => 255, :null => false, :default => ''
    add_column :search_suggestions, :scientific_name, :string, :limit => 255, :null => false, :default => ''
    add_column :search_suggestions, :image_url, :string, :limit => 255, :null => false, :default => ''
  end
end
