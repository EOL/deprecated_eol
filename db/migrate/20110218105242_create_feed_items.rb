class CreateFeedItems < ActiveRecord::Migration
  def self.up
    create_table :feed_items do |t|
      t.string :thumbnail_url
      t.string :body
      t.string :feed_type
      t.integer :feed_id
      t.string :subject_type
      t.integer :subject_id
      t.string :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :feed_items
  end
end
