class CreateCommunityActivityLog < EOL::LoggingMigration
  def self.up
    create_table :community_activity_logs do |t|
      t.integer :user_id, :null => false
      t.integer :activity_id, :null => false
      t.integer :community_id, :null => false
      t.integer :member_id           # for adding members
      t.integer :member_privilege_id # For adding privs
      t.datetime :created_at, :null => false
    end
    add_index :collection_activity_logs, :created_at
  end

  def self.down
    drop_table :community_activity_logs
  end
end
