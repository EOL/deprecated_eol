class RemoveCollectionIdFromActLog < EOL::LoggingMigration
  def self.up
    remove_column :community_activity_logs, :collection_id
  end

  def self.down
    add_column :community_activity_logs, :collection_id, :integer
  end
end
