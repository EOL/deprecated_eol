class AlterDataSearchFilesQ < ActiveRecord::Migration
  def self.up
    change_column :data_search_files, :q, :string, limit: 512, null: true
  end
  
  def self.down
    change_column :data_search_files, :q, :string, limit: 512, null: false
  end
end
