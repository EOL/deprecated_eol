class CreateTaskNames < ActiveRecord::Migration
  def self.up
    create_table :task_names do |t|
      t.string :description, :limit => 200
      t.integer :frequency, :default => 1
      t.timestamps
    end
  end

  def self.down
    drop_table :task_names
  end
end
