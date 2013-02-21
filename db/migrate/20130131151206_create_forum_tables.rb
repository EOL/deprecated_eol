class CreateForumTables < ActiveRecord::Migration
  def self.up
    create_table :forum_categories do |t|
      t.string :title, :null => false
      t.text :description
      t.integer :view_order, :default => 0, :null => false
      t.integer :user_id
      t.timestamps
    end

    create_table :forums do |t|
      t.integer :forum_category_id, :null => false
      t.string :name, :null => false
      t.text :description
      t.integer :view_order, :default => 0, :null => false
      t.integer :number_of_posts, :default => 0, :null => false
      t.integer :number_of_topics, :default => 0, :null => false
      t.integer :number_of_views, :default => 0, :null => false
      t.integer :last_post_id
      t.integer :user_id, :null => false
      t.timestamps
    end

    create_table :forum_topics do |t|
      t.integer :forum_id, :null => false
      t.string :title, :null => false
      t.integer :number_of_posts, :default => 0, :null => false
      t.integer :number_of_views, :default => 0, :null => false
      t.integer :first_post_id
      t.integer :last_post_id
      t.integer :user_id, :null => false
      t.timestamps
    end

    create_table :forum_posts do |t|
      t.integer :forum_topic_id, :null => false
      t.string :subject, :null => false
      t.text :text, :null => false
      t.integer :user_id, :null => false
      t.integer :reply_to_post_id
      t.integer :edit_count, :default => 0, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :forum_categories
    drop_table :forums
    drop_table :forum_topics
    drop_table :forum_posts
  end
end
