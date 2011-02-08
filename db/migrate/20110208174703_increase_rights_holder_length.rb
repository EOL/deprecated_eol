class IncreaseRightsHolderLength < EOL::DataMigration
  def self.up
    execute("ALTER TABLE data_objects MODIFY `rights_holder` TEXT NOT NULL COMMENT 'a string stating the owner of copyright for this object'")
  end
  
  def self.down
    execute("ALTER TABLE data_objects MODIFY `rights_holder` varchar(255) NOT NULL COMMENT 'a string stating the owner of copyright for this object'")
  end
end
