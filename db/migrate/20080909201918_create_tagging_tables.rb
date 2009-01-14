class CreateTaggingTables < ActiveRecord::Migration
  def self.up

    create_table :data_object_tags, :comment => 'unique key/value pairs for tagging data_objects' do |t|
      t.string :key, :null => false
      t.string :value, :null => false
      t.boolean :is_public, :comment => "whether this tag is 'approved'/'official'"
      t.integer :total_usage_count, :comment => 'cached number of total uses of this tag'
      t.timestamps
    end

    create_table :data_object_data_object_tags, :comment => 'join table for data_objects and data_object_tags' do |t|
      t.integer :data_object_id, :null => false
      t.integer :data_object_tag_id, :null => false
      t.integer :user_id, :comment => 'the id of the user who added the tag (if added by a user and not by EOL)'
    end

  end

  def self.down
    drop_table :data_object_tags
    drop_table :data_object_data_object_tags
  end
end
