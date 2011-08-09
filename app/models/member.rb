class Member < ActiveRecord::Base

  belongs_to :community
  belongs_to :user

  named_scope :managers, :conditions => {:manager => true}
  named_scope :nonmanagers, :conditions => 'manager IS NULL or manager = 0'

  validates_uniqueness_of :user_id, :scope => :community_id

  # You should be able to call manager? to test whether the member is ... uhhh... a manager.

  def grant_manager
    self.update_attribute(:manager, true)
  end

  def revoke_manager
    self.update_attribute(:manager, false)
  end

end
