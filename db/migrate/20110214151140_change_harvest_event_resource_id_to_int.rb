class ChangeHarvestEventResourceIdToInt < EOL::DataMigration
  def self.up
    execute("ALTER TABLE harvest_events MODIFY `resource_id` int(10) unsigned NOT NULL")
  end
  
  def self.down
    execute("ALTER TABLE harvest_events MODIFY `resource_id` varchar(100) character set ascii NOT NULL")
  end
end
