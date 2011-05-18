class RemoveCuratorClades < ActiveRecord::Migration
  def self.up
    remove_column :users, :curator_hierarchy_entry_id
  end

  def self.down
    execute 'ALTER TABLE `users` ADD `curator_hierarchy_entry_id` int(11) default NULL after `notes`'
  end
end
