class Member < ActiveRecord::Base

  belongs_to :community
  belongs_to :user

  validates_uniqueness_of :user_id, :scope => :community_id

  # You should be able to call manager? to test whether the member is ... uhhh... a manager.

  def grant_manager
    self.update_attribute(:manager, true)
  end

  def revoke_manager
    self.update_attribute(:manager, false)
  end

end
