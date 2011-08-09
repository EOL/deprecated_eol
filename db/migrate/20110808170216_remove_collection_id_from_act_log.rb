class RemoveCollectionIdFromActLog < EOL::LoggingMigration
  def self.up
    # TODO: this column never existed. Do we need this migration?
    # remove_column :community_activity_logs, :collection_id
  end

  def self.down
    # add_column :community_activity_logs, :collection_id, :integer
  end
end
