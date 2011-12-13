class AddHiddenToComment < ActiveRecord::Migration
  def self.up
    add_column :comments, :hidden, :tinyint, :default => 0
  end

  def self.down
    remove_column :comments, :hidden
  end
end
