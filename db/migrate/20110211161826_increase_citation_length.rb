class IncreaseCitationLength < EOL::DataMigration
  def self.up
    execute("ALTER TABLE data_objects MODIFY `bibliographic_citation` TEXT NOT NULL")
  end
  
  def self.down
    execute("ALTER TABLE data_objects MODIFY `bibliographic_citation` varchar(300) NOT NULL")
  end
end
