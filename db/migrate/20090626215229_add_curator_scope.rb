class AddCuratorScope < ActiveRecord::Migration
  def self.up
    add_column :users, :curator_scope, :text, :default => '', :null => false
  end

  def self.down
    remove_column :users, :curator_scope
  end
end
