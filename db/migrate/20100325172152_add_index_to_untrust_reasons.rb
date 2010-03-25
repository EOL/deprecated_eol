class AddIndexToUntrustReasons < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  
  def self.up
    execute 'create index data_object_id on data_objects_untrust_reasons(data_object_id)'
  end
  
  def self.down
    execute 'drop index data_object_id ON data_objects_untrust_reasons'
  end
end
