class AddPreferredClassificationToActivities < EOL::LoggingMigration
  def self.up
    Activity.find_or_create('preferred_classification')
  end

  def self.down
    # Nothing to do.
  end
end
