class AddIndexToCommentsCreatedAt < ActiveRecord::Migration
  def self.up
    execute("create index created_at on comments (created_at)")
  end

  def self.down
    remove_index :comments, :name => 'created_at'
  end
end
