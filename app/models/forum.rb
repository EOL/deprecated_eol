class Forum < ActiveRecord::Base

  belongs_to :forum_category
  belongs_to :last_post, :class_name => 'ForumPost', :foreign_key => :last_post_id
  belongs_to :user

  has_many :forum_topics

  validates_presence_of :name

  before_create :set_view_order
  before_update :reset_view_order_if_category_changed

  TOPICS_PER_PAGE = 30

  def can_be_deleted_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end
  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end

  def update_last_post_and_count
    update_attributes(:last_post_id => open_topics.maximum('forum_posts.id'))
    update_attributes(:number_of_posts => open_topics.count)
  end

  def open_topics
    forum_topics.visible.joins(:forum_posts).where("forum_posts.deleted_at IS NULL")
  end

  private

  def reset_view_order_if_category_changed
    set_view_order if forum_category_id_changed?
  end

  def set_view_order
    self.view_order = (Forum.where(:forum_category_id => self.forum_category_id).maximum(:view_order) || 0) + 1
  end

end
