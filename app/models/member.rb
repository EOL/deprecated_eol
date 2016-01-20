class Member < ActiveRecord::Base

  belongs_to :community
  belongs_to :user

  scope :managers, conditions: { manager: true }
  scope :nonmanagers, conditions: 'manager IS NULL or manager = 0'
  scope :recent_community_owner, ->(current_user) {
    where(user_id: current_user.id, manager: true,
    created_at: DateTime.now.in_time_zone.to_date.beginning_of_day..DateTime.now.in_time_zone.to_date.end_of_day)
  }
  validates_uniqueness_of :user_id, scope: :community_id

  # You should be able to call manager? to test whether the member is ... uhhh... a manager.

  def grant_manager
    self.update_attributes(manager: true)
  end

  def revoke_manager
    self.update_attributes(manager: false)
  end

  def comment_count
    Comment.count_by_sql(%Q{
      SELECT COUNT(*) FROM comments
      WHERE parent_type = "Community" AND parent_id = #{self.community_id} AND user_id = #{self.user_id}
    })
  end

end
