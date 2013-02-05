class Forum < ActiveRecord::Base

  belongs_to :forum_category
  belongs_to :last_post, :class_name => 'ForumPost', :foreign_key => :last_post_id
  belongs_to :user

  has_many :forum_topics

  validates_presence_of :name

  before_create :set_view_order

  def can_be_deleted_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end
  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end

  private

  def set_view_order
    self.view_order = (Forum.where(:forum_category_id => self.forum_category_id).maximum('view_order') || 0) + 1
  end

end
