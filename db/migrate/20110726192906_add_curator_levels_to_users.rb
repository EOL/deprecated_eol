class AddCuratorLevelsToUsers < ActiveRecord::Migration
  def self.up
    create_table :curator_levels do |t|
      t.string :label, :null => false
    end
    CuratorLevel.create_defaults
    add_column :users, :curator_level_id, :integer
    add_column :users, :requested_curator_level_id, :integer
  end

  def self.down
    drop_table :curator_levels
    remove_column :users, :curator_level_id
    remove_column :users, :requested_curator_level_id
  end
end
