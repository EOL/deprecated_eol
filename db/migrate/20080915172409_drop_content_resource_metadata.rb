class DropContentResourceMetadata < ActiveRecord::Migration
  # This is just the inverse of the create version!
  def self.down
    create_table :content_resource_metadatas do |t|
      t.string :label
      t.text :special_instructions
      t.string :resource
      t.references :agent
      t.integer :frequency_in_days
      t.references :license
      t.timestamps
    end
  end

  def self.up
    drop_table :content_resource_metadatas
  end
end
