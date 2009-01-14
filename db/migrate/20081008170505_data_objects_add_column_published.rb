class DataObjectsAddColumnPublished < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    change_table :data_objects do |t|
      t.boolean :published, :null => false, :default => 0
      t.index :published
    end
    
    change_table :content_partners do |t|
      t.boolean :auto_publish, :null => false, :default => 0 
    end

    change_table :resources do |t|
      t.boolean :auto_publish, :null => false, :default => 0 
      t.integer :active_harvest_event_id
    end



  end

  def self.down
    remove_column :resources, :active_harvest_event_id
    remove_column :resources, :auto_publish
    remove_column :content_partners, :auto_publish
    remove_column :data_objects, :published
  end
end
