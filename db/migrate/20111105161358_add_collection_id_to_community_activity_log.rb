class AddCollectionIdToCommunityActivityLog < EOL::LoggingMigration
  def self.up
    add_column :community_activity_logs, :collection_id
  end

  def self.down
    remove_column :community_activity_logs, :collection_id
  end
end
