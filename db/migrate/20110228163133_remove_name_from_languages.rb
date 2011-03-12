class RemoveNameFromLanguages < EOL::DataMigration
  def self.up
    remove_column :languages, :name
  end

  def self.down
    execute('ALTER TABLE `languages` ADD `name` varchar(100) NOT NULL AFTER `label`')
    execute('UPDATE languages SET name = source_form')
  end
end
