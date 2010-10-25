class CreateCuratorObjectIgnoreList < ActiveRecord::Migration
  def self.up
    create_table :user_ignored_data_objects do |t|
      t.integer :user_id, :null => false
      t.integer :data_object_id, :null => false
      t.timestamp :created_at
    end
  end

  def self.down
    drop_table :user_ignored_data_objects
  end
end
