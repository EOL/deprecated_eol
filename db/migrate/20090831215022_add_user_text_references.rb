class AddUserTextReferences < EOL::DataMigration
  
  def self.up
    add_column :refs, :user_submitted, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :refs, :user_submitted
  end

end
