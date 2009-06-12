class CreateActionWithObjects < ActiveRecord::Migration
  def self.up
    create_table :action_with_objects do |t|
      t.string :action_code,  
               :comment => 'What one can do with DataObject (create, delete, curate...)'
      t.timestamps
    end
  end

  def self.down
    drop_table :action_with_objects
  end
end
