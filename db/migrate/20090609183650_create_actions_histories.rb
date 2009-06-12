class CreateActionsHistories < ActiveRecord::Migration
  def self.up
    create_table :actions_histories do |t|
      t.integer  :user_id
      t.integer  :object_id
      t.integer  :changeable_object_type_id	
      t.integer  :action_with_object_id
      t.timestamps
    end
  end

  def self.down
    drop_table :actions_histories
  end
end
