class CreateResourceStatuses < ActiveRecord::Migration
  def self.database_model
    return "SpeciesSchemaModel"
  end
  def self.up
    create_table :resource_statuses do |t|
      t.string :label
      t.timestamps
    end
    ResourceStatus.create(:label => 'Uploading')
    ResourceStatus.create(:label => 'Uploaded')
    ResourceStatus.create(:label => 'Upload Failed')
    ResourceStatus.create(:label => 'Moved to Content Server')
    ResourceStatus.create(:label => 'Validated')
    ResourceStatus.create(:label => 'Validation Failed')
    ResourceStatus.create(:label => 'Being Processed')
    ResourceStatus.create(:label => 'Processed')
    ResourceStatus.create(:label => 'Processing Failed')
    ResourceStatus.create(:label => 'Published')
    add_column :resources, :resource_status_id, :integer
  end

  def self.down
    remove_column :resources, :resource_status_id
    drop_table :resource_statuses
  end
end
