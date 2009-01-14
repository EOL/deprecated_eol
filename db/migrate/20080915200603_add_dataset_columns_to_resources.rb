class AddDatasetColumnsToResources < ActiveRecord::Migration

  def self.database_model
    return "SpeciesSchemaModel"
  end

  def self.up
    add_column :resources,:dataset_file_name,:string
    add_column :resources,:dataset_content_type,:string
    add_column :resources,:dataset_file_size,:integer
  end

  def self.down
    remove_column :resources,:dataset_file_name
    remove_column :resources,:dataset_content_type
    remove_column :resources,:dataset_file_size
  end
  
end
