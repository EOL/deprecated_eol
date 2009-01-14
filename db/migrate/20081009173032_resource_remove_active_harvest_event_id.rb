class ResourceRemoveActiveHarvestEventId < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    remove_column :resources, :active_harvest_event_id
  end

  def self.down
    change_table :resources do |t|
      t.integer :active_harvest_event_id
    end

    
  end
end
