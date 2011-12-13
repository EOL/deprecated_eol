class AddHiddenToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :hidden, :tinyint, :default => 0
  end

  def self.down
    remove_column :users, :hidden
  end
end
