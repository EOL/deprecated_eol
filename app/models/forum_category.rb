class ForumCategory < ActiveRecord::Base

  belongs_to :user
  has_many :forums

  validates_presence_of :title

  before_create :set_view_order

  def can_be_deleted_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end
  def can_be_updated_by?(user_wanting_access)
    user_wanting_access.is_admin?
  end

  def self.with_forums
    ForumCategory.joins(:forums).select('DISTINCT forum_categories.*').order(:view_order)
  end

  private

  def set_view_order
    self.view_order = (ForumCategory.maximum('view_order') || 0) + 1
  end

end
