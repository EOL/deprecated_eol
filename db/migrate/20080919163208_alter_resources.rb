class AlterResources < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  def self.up
    change_table :resources do |t|
      t.change :harvested_at, :timestamp, :null => true
      t.change :resource_modified_at, :timestamp, :null => true
      t.change :resource_created_at, :timestamp, :null => true
      t.change :accesspoint_url, :string, :null => true 
      t.change :rights_statement, :string, :null => true, :limit => 400
      t.change :rights_holder, :string, :null => true
      t.change :description, :string, :null => true           
    end
  end

  def self.down
    change_table :resources do |t|
      t.change :harvested_at, :timestamp, :null => false, :default => '0000-00-00 00:00:00'
      t.change :resource_modified_at, :timestamp, :null => false, :default => '0000-00-00 00:00:00'
      t.change :resource_created_at, :timestamp, :null => false, :default => '0000-00-00 00:00:00'
      t.change :accesspoint_url, :string, :null => false
      t.change :rights_statement, :string, :null => false, :limit => 400
      t.change :rights_holder, :string, :null => false
      t.change :description, :string, :null => false
    end
  end
end
