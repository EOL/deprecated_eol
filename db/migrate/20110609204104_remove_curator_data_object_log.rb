class RemoveCuratorDataObjectLog < EOL::LoggingMigration
  def self.up
    drop_table :curator_data_object_logs
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration.new("curator_data_object_logs was removed and cannot be restored.")
  end
end
