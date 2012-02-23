class AddJoinAndLeaveActions < EOL::LoggingMigration

  def self.up
    Activity.find_or_create('join')
    Activity.find_or_create('leave')
  end

  def self.down
    # Nothing to do.
  end

end
