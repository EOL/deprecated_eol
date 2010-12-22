class MemberPrivilege < ActiveRecord::Base

  has_many :privileges
  has_many :members

  def revoked?
    revoked
  end

end
