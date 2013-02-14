class ForumTopic < ActiveRecord::Base

  belongs_to :forum
  belongs_to :user
  belongs_to :first_post, :class_name => 'ForumPost', :foreign_key => :first_post_id
  belongs_to :last_post, :class_name => 'ForumPost', :foreign_key => :last_post_id
  has_many :forum_posts

  accepts_nested_attributes_for :forum_posts

  after_create :update_forum
  after_destroy :update_forum

  POSTS_PER_PAGE = 30

  def can_be_deleted_by?(user_wanting_access)
    user == user_wanting_access || user_wanting_access.is_admin? || first_post.user == user_wanting_access
  end
  def can_be_updated_by?(user_wanting_access)
    user == user_wanting_access || user_wanting_access.is_admin? || first_post.user == user_wanting_access
  end

  private

  def update_forum
    forum.update_attributes(:number_of_topics => forum.forum_topics.count)
  end

end
