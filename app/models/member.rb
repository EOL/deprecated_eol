class Member < ActiveRecord::Base

  belongs_to :community
  belongs_to :user
  has_and_belongs_to_many :privileges

  validates_uniqueness_of :user_id, :scope => :community_id

  def assign_privileges(privileges)
    privileges += privileges
    save!
  end

end
