class CreateWorklistIgnoredDataObjects < ActiveRecord::Migration
  def self.up
    create_table :worklist_ignored_data_objects do |t|
      t.integer :user_id
      t.integer :data_object_id, :null => false
      t.datetime :created_at
    end
    add_index :worklist_ignored_data_objects, :data_object_id
  end

  def self.down
    drop_table :worklist_ignored_data_objects
  end
end