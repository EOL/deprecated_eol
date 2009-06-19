class CommentsMustHaveUsers < ActiveRecord::Migration
  def self.up
    change_column :comments, :user_id, :integer, :null => false
    admin = User.find_by_username('admin')
    Comment.find(:all, :conditions => 'user_id = 0').each do |comment|
      comment.user = admin
      comment.save!
    end
  end

  def self.down
    change_column :comments, :user_id, :integer, :null => true
  end
end
