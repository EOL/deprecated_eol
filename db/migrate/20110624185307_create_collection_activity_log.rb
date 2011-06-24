class CreateCollectionActivityLog < EOL::LoggingMigration
  def self.up
    create_table :collection_activity_logs do |t|
      t.integer :user_id, :null => false
      t.integer :collection_id, :null => false
      t.integer :collection_item_id
      t.integer :activity_id, :null => false
      t.datetime :created_at, :null => false
    end
    add_index :collection_activity_logs, :created_at
    add_index :collection_activity_logs, :collection_id
    add_index :collection_activity_logs, :user_id
  end

  def self.down
    drop_table :collection_activity_logs
  end
end
