class AddNotificationPreparationTimesInLogging < EOL::LoggingMigration

  def self.up
    add_column :curator_activity_logs, :notifications_prepared_at, :datetime
    CuratorActivityLog.connection.execute("UPDATE #{CuratorActivityLog.table_name} SET notifications_prepared_at = '#{Time.now}'")
    add_column :community_activity_logs, :notifications_prepared_at, :datetime
    CommunityActivityLog.connection.execute("UPDATE #{CommunityActivityLog.table_name} SET notifications_prepared_at = '#{Time.now}'")
    add_column :collection_activity_logs, :notifications_prepared_at, :datetime
    CollectionActivityLog.connection.execute("UPDATE #{CollectionActivityLog.table_name} SET notifications_prepared_at = '#{Time.now}'")
  end

  def self.down
    remove_column :collection_activity_logs, :notifications_prepared_at
    remove_column :community_activity_logs, :notifications_prepared_at
    remove_column :curator_activity_logs, :notifications_prepared_at
  end

end
