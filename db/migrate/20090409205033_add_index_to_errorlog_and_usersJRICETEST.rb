class AddIndexToErrorlogAndUsers < ActiveRecord::Migration
  def self.up
    add_index :error_logs, :created_at
    add_index :users, :created_at
  end

  def self.down
    remove_index :error_logs, :created_at
    remove_index :users, :created_at
  end
end
