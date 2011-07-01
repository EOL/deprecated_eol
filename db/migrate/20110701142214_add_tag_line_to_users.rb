class AddTagLineToUsers < ActiveRecord::Migration
  def self.up
    execute('ALTER TABLE users ADD `tag_line` varchar(255) default NULL')
  end

  def self.down
    remove_column :users, :tag_line
  end
end
