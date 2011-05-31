class CreateContentTableItems < ActiveRecord::Migration
  def self.up
    create_table :content_table_items, :id => false do |t|
      t.references :content_table, :null => false
      t.integer :toc_id, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :content_table_items
  end
end
