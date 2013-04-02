class ForumTopic < ActiveRecord::Base

  belongs_to :forum
  belongs_to :user
  belongs_to :first_post, :class_name => 'ForumPost', :foreign_key => :first_post_id
  belongs_to :last_post, :class_name => 'ForumPost', :foreign_key => :last_post_id
  has_many :forum_posts

  scope :visible, where(:deleted_at => nil)

  accepts_nested_attributes_for :forum_posts

  after_create :update_forum
  after_update :update_forum

  POSTS_PER_PAGE = 30

  def can_be_deleted_by?(user_wanting_access)
    user == user_wanting_access || user_wanting_access.is_admin? || first_post.user == user_wanting_access
  end
  def can_be_updated_by?(user_wanting_access)
    user == user_wanting_access || user_wanting_access.is_admin? || first_post.user == user_wanting_access
  end

  def increment_view_count
    update_attributes(:number_of_views => number_of_views + 1)
  end

  def set_first_post
    if first_post.nil? && post = ForumPost.where(:forum_topic_id => id).first
      update_attributes(:first_post_id => post.id)
    end
  end

  def set_last_post
    update_attributes(:last_post_id => forum_posts.visible.maximum(:id))
  end

  def set_post_count
    update_attributes(:number_of_posts => forum_posts.visible.count)
  end

  private

  def update_forum
    forum.update_attributes(:number_of_topics => forum.open_topics.count)
  end

end
