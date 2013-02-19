class AddDeleteToPostsAndTopics < ActiveRecord::Migration
  def self.up
    add_column :forum_posts, :deleted_at, :datetime
    add_column :forum_posts, :deleted_by_user_id, :integer
    add_column :forum_topics, :deleted_at, :datetime
    add_column :forum_topics, :deleted_by_user_id, :integer
    add_column :users, :number_of_forum_posts, :integer
  end

  def self.down
    remove_column :forum_posts, :deleted_at
    remove_column :forum_posts, :deleted_by_user_id
    remove_column :forum_topics, :deleted_at
    remove_column :forum_topics, :deleted_by_user_id
    remove_column :users, :number_of_forum_posts
  end
end
