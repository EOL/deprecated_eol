class DropCuratorActivity < EOL::LoggingMigration
  def self.up
    drop_table :curator_activities
  end

  def self.down
    raise ActiveRecord::IrreversibleMigrationError.new("Cannot restore curator_activities table")
  end
end
