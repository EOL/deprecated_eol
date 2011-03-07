class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.integer :task_name_id
      t.integer :task_state_id
      t.integer :owner_user_id
      t.integer :created_by_user_id
      t.integer :target_id
      t.string :target_type, :limit => 32
      t.datetime :expires_on

      t.timestamps
    end
  end

  def self.down
    drop_table :tasks
  end
end
