class ForumCategory < ActiveRecord::Base

  belongs_to :user
  has_many :forums

  validates_presence_of :title

  before_create :set_view_order

  def self.with_forums
    ForumCategory.joins(:forums).select('DISTINCT forum_categories.*').order(:view_order)
  end

  private

  def set_view_order
    self.view_order = (ForumCategory.maximum('view_order') || 0) + 1
  end

end
