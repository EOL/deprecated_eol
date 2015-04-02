class CreateDataSearchFileEquivalents < ActiveRecord::Migration
  def up
    create_table :data_search_file_equivalents do |t|
      t.integer :data_search_file_id, :null => false
      t.integer :uri_id, :null => false
      t.boolean :is_attribute, :null => false
    end
    add_index :data_search_file_equivalents, [:data_search_file_id, :uri_id], :unique => true, :name => 'data_search_file_and_uri'
    add_index :data_search_file_equivalents, :data_search_file_id
  end
  
  def down
    drop_table :data_search_file_equivalents
  end
end