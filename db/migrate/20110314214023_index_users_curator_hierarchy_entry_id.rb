class IndexUsersCuratorHierarchyEntryId < ActiveRecord::Migration
  def self.up
    execute('CREATE INDEX `curator_hierarchy_entry_id` ON `users`(`curator_hierarchy_entry_id`)')
  end

  def self.down
    remove_index :users, :name => 'curator_hierarchy_entry_id'
  end
end
