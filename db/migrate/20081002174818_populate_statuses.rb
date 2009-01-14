class PopulateStatuses < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  def self.up
    execute "insert into statuses (label) values 
      ('Inserted'),
      ('Updated'),
      ('Unchanged')"
  end

  def self.down
    execute "delete from statuses"
  end
end
