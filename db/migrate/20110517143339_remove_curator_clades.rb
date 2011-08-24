class RemoveCuratorClades < ActiveRecord::Migration
  def self.up
    execute "update users u
              join hierarchy_entries he on he.id = u.curator_hierarchy_entry_id
              join names n on n.id = he.name_id
              set u.curator_scope = n.string
              where u.curator_scope IS NULL OR u.curator_scope = ''"
    remove_column :users, :curator_hierarchy_entry_id
  end

  def self.down
    execute 'ALTER TABLE `users` ADD `curator_hierarchy_entry_id` int(11) default NULL after `notes`'
  end
end
