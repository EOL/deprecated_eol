class CreateHarvestProcessLog < EOL::DataMigration
  def self.up
    create_table :harvest_process_logs do |t|
      t.string :process_name
      t.timestamp :began_at
      t.timestamp :completed_at
    end
  end

  def self.down
      drop_table :harvest_process_logs
  end
end
