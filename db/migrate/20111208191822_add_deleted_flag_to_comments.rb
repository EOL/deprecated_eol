class AddDeletedFlagToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :deleted, :tinyint, :default => 0
  end

  def self.down
    remove_column :comments, :deleted
  end
end