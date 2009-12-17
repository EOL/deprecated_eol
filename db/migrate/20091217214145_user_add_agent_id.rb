class UserAddAgentId < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE users ADD COLUMN agent_id int(10) unsigned"
    add_index :users, :agent_id, :name => "index_users_on_agent_id", :unique => true
  end

  def self.down
    remove_column :users, :agent_id
  end
end
