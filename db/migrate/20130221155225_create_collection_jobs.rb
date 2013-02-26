class CreateCollectionJobs < ActiveRecord::Migration
  def change
    create_table :collection_jobs do |t|
      t.string :command, :limit => 8, :null => false
      t.integer :user_id, :null => false
      t.integer :collection_id, :null => false
      t.integer :target_collection_id
      t.integer :item_count
      t.boolean :all_items, :default => false
      t.timestamps
      t.datetime :finished_at
    end
    create_table :collection_items_collection_jobs do |t|
      t.integer :collection_item_id, :null => false
      t.integer :collection_job_id, :null => false
    end
    add_index :collection_items_collection_jobs, [:collection_item_id, :collection_job_id], :unique => true, :name => 'join_index'
  end
end
